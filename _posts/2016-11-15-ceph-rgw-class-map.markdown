---
layout: post
title: Ceph v10.2.3 RGW源码解析2
---

看rgw代码的时间很短，对于rgw代码的脉络还摸不着头脑。恰巧看某博主的大作：RGW类图，遂分析之。

### RGWOps
```
/**
 * All operations via the rados gateway are carried out by
 * small classes known as RGWOps. This class contains a req_state
 * and each possible command is a subclass of this with a defined
 * execute() method that does whatever the subclass name implies.
 * These subclasses must be further subclassed (by interface type)
 * to provide additional virtual methods such as send_response or get_params.
 */
```
上面这句，引用自rgw_op.h，说到了rgw实现的一个关键线索。

所有通过rgw的操作，都会封装成一个RGWOps, 这个类里面包含req_state。每一个命令都是一个定义了execute()方法的子类。
每个子类，还可以进一步继承，实现一些其他方法，如send_response、get_params。

### RGWGetObj
我们找到一个具体的操作，RGWGetObj也就是GET一个对象。浏览代码之后，发现关键的地方在于：
```
  RGWRados::Object op_target(store, s->bucket_info, *static_cast<RGWObjectCtx *>(s->obj_ctx), obj);
  RGWRados::Object::Read read_op(&op_target);
```
定义了一个RGWRados::Object对象，然后基于这个对象定义了一个Read，这个Read应该是封装了rados操作，来支持GET的逻辑。

### RGWPeriod
这个是什么鬼？似乎跟周期相关。但：
```
struct RGWPeriodConfig
{
  RGWQuotaInfo bucket_quota;
  RGWQuotaInfo user_quota;

```
RGWPeriodConfig却是关于Quota的。。。

### RGWRados::Object::Read::prepare 
```
/**
 * Get data about an object out of RADOS and into memory.
 * bucket: name of the bucket the object is in.
 * obj: name/key of the object to read
 * data: if get_data==true, this pointer will be set
 *    to an address containing the object's data/value
 * ofs: the offset of the object to read from
 * end: the point in the object to stop reading
 * attrs: if non-NULL, the pointed-to map will contain
 *    all the attrs of the object when this function returns
 * mod_ptr: if non-NULL, compares the object's mtime to *mod_ptr,
 *    and if mtime is smaller it fails.
 * unmod_ptr: if non-NULL, compares the object's mtime to *unmod_ptr,
 *    and if mtime is >= it fails.
 * if_match/nomatch: if non-NULL, compares the object's etag attr
 *    to the string and, if it doesn't/does match, fails out.
 * get_data: if true, the object's data/value will be read out, otherwise not
 * err: Many errors will result in this structure being filled
 *    with extra informatin on the error.
 * Returns: -ERR# on failure, otherwise
 *          (if get_data==true) length of read data,
 *          (if get_data==false) length of the object
 */
// P3 XXX get_data is not seen used anywhere.
int RGWRados::Object::Read::prepare(int64_t *pofs, int64_t *pend)
{
```
上面一段注释很受用。

### 插播
刚才在使用cosbench测试单机版ceph，出现mon挂掉的场景，查看log：

```
175342 2016-11-15 10:02:55.384666 7f68b99e0700 10 mon.a@0(leader).data_health(3) share_stats
175343 2016-11-15 10:02:55.384674 7f68b99e0700 -1 mon.a@0(leader).data_health(3) reached critical levels of availa       ble space on local monitor storage -- shutdown!
175344 2016-11-15 10:02:55.384676 7f68b99e0700  0 ** Shutdown via Data Health Service **
```


### 参考

[某博主类图赞个](http://img.blog.csdn.net/20161109100532308?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)
