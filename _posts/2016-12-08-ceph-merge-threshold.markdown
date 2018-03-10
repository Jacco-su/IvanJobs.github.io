---
layout: post
title: Ceph故障解析-filestore_merge_threshold
category: ops 
---

最近参与了一项Ceph新老集群数据迁移的工作，在解决Block Requests故障领域，积累了第一份经验。本篇博客，旨在介绍
这次故障的现象以及原理分析。

### 背景描述
ceph老集群有大概3亿的对象需要迁移，于是基于S3接口，一方面从老集群GET，另一方面向新集群PUT。
代码实现上，有一些核心细节：session复用，并发节流。

在迁移过程中，我们发现：迁移一定量数据之后，新Ceph集群就会出现大量Block Requests，并且伴有OSD的Down，fs_apply_latency奇高（几十秒级别）。
迁移速度根本无法接受。之后，我们尝试了各种方法，包括调优Ceph参数、调优文件系统参数、map index pool到SSD、使用SSD journal等，都未能解决本质问题。同样的问题，还是一再的重现。

### 问题解决
小伙伴们在“尸体”上进行观察，注意到一个现象，PG目录下的文件数，几乎都达到了5K级别。于是，自然的想到了单目录下文件个数不能太多，否则fs性能影响很大。
于是，照着这个靠谱的思路，重建集群、修改Ceph相关的配置参数，最终解决了问题。

### 原理解析

##### filestore_merge_threshold和filestore_split_multiple
这两个参数，决定了split的上限： abs(filestore_merge_threshold) * 16 * filestore_split_multiple。

filestore_merge_threshold决定了merge的下限。

```
  // Do the folder splitting first
  ret = pre_split_folder(pg_num, expected_num_objs);
  if (ret < 0)
    return ret;
  // Initialize the folder info starting from root
  return init_split_folder(path, 0);
}

int HashIndex::pre_split_folder(uint32_t pg_num, uint64_t expected_num_objs)
{
  // If folder merging is enabled (by setting the threshold positive),
  // no need to split
  if (merge_threshold > 0)
    return 0;
  const coll_t c = coll();
  // Do not split if the expected number of objects in this collection is zero (by default)
  if (expected_num_objs == 0)
    return 0;

  // Calculate the number of leaf folders (which actually store files)
  // need to be created
  const uint64_t objs_per_folder = (uint64_t)(abs(merge_threshold)) * (uint64_t)split_multiplier * 16;
  uint64_t leavies = expected_num_objs / objs_per_folder ;
```
pre_split_folder用于对split做准备工作，init_split_folder:
```
int HashIndex::init_split_folder(vector<string> &path, uint32_t hash_level)
{
  // Get the number of sub directories for the current path
  vector<string> subdirs;
  int ret = list_subdirs(path, &subdirs);
  if (ret < 0)
    return ret;
  subdir_info_s info;
  info.subdirs = subdirs.size();
  info.hash_level = hash_level;
  ret = set_info(path, info);
  if (ret < 0)
    return ret;
  ret = fsync_dir(path);
  if (ret < 0)
    return ret;

  // Do the same for subdirs
  vector<string>::const_iterator iter;
  for (iter = subdirs.begin(); iter != subdirs.end(); ++iter) {
    path.push_back(*iter);
    ret = init_split_folder(path, hash_level + 1);
    if (ret < 0)
      return ret;
    path.pop_back();
  }
  return 0;
}
```
递归遍历子目录，list_subdirs是干什么的？
```
int LFNIndex::list_subdirs(const vector<string> &to_list,
               vector<string> *out)
{
  string to_list_path = get_full_path_subdir(to_list);
  DIR *dir = ::opendir(to_list_path.c_str());
  char buf[offsetof(struct dirent, d_name) + PATH_MAX + 1];
  if (!dir)
    return -errno;

  struct dirent *de;
  while (!::readdir_r(dir, reinterpret_cast<struct dirent*>(buf), &de)) {
    if (!de) {
      break;
    }
    string short_name(de->d_name);
    string demangled_name;
    if (lfn_is_subdir(short_name, &demangled_name)) {
      out->push_back(demangled_name);
    }
  }

  ::closedir(dir);
  return 0;
}
```
仅仅是递归遍历了目录，不是split核心逻辑所在。
```
int HashIndex::complete_split(const vector<string> &path, subdir_info_s info) {
  int level = info.hash_level;
  map<string, ghobject_t> objects;
  vector<string> dst = path;
  int r;
  dst.push_back("");
  r = list_objects(path, 0, 0, &objects);
  if (r < 0)
    return r;
```
complete_split时会list_objects。

以上大概列举了一些关键代码片段，具体的逻辑还需要深入研读源码。但有一点可以判断出来，就是在split的时候，确实会list_objects, 而且底层使用的是readdir_r。


##### XFS目录下文件个数，到底对性能影响有多大？
测试代码：
```
#include <sys/types.h>
#include <dirent.h>
#include <errno.h>
#include <stdio.h>

int main() {
  int return_code;
  DIR *dir;
  struct dirent entry;
  struct dirent *result;

  if ((dir = opendir("./tmp")) == NULL)
    perror("opendir() error");
  else {
    for (return_code = readdir_r(dir, &entry, &result);
         result != NULL && return_code == 0;
         return_code = readdir_r(dir, &entry, &result))
        ;//do nothing
    if (return_code != 0)
      perror("readdir_r() error");
    closedir(dir);
  }

  return 0;
}
```
测试结果：

1. 100: 0.001s
2. 200: 0.001s
3. 400: 0.001s
4. 800: 0.001s
5. 1600: 0.001s
6. 3200: 0.001s
7. 6400: 0.001s
8. 12800: 0.002s
9. 25600: 0.002s
10. 50000: 0.004s
11. 100000: 0.007s
...

这个测试结果，可能看不出什么。因为测试脚本遍历每个对象，什么事也没做。如果把这部分加上，目录下文件个数，对整体性能的影响可见一斑。


### 总结
1. 不可以*不加测试*的应用第三方的调优参数。
2. 写入和重启OSD都会触发split check。
3. commit是写日志、apply是写数据。
4. 短暂的低性能和block requests属于正常现象。


