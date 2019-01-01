---
layout: post
title: OSTEP 文件系统实现
category: dev 
---
只要掌握两个方面的内容，就可以掌握文件系统，一个是数据结构，另一个是访问方法。数据结构关注的是文件系统的一个存储形式，访问方法关注的是文件系统的使用形式，两者有内在的对应关系。

### vsfs存储布局
磁盘按照4KB划分一个block，一共有64个blcok。

后7x8个block用作data region, 存储文件内容。

第3-7个block用作inode table, 存储inode结构，每一个inode结构占用的空间是固定的，所以可以计算出存储inode个数上限。

第2个block,作为一个bitmap,保存data region中free的block情况。

第1个block，作为一个bitmap,保存inode table中free的inode空间情况。

第0个block，叫做Super Block, 包括一些信息：总共多少个data blocks, 多少个inodes, inode table从哪里开始等等。也有可能包含一个magic number,用于代表文件系统类型。操作系统mount文件系统的时候，会首先读取Super Block中的内容，初始化一些信息，然后把当前卷挂到文件目录树中，当访问该目录的时候，操作系统就知道如何去定位文件和文件元数据了。

### inode
有了以上存储布局的规划，我们很容易根据一个inode number,计算到该inode的地址，进而读取内容。inode中除了包含我们常见的一些元数据外，比较关键的是其如何表达文件内容的位置，即一些blocks。一种方法是，直接存多个blocks的地址，这样的方法比较简单直接，但是我们知道inode结构的空间是均匀有限的，如果文件很大，存不下怎么办？

这时候的一种方案是，利用data region的block存储地址，在inode中只保存一个间接地址，这个地址指向的block包含更多的实际指向data block的地址，可以按照这个思路解决大文件的问题。可以增加间接引用的存储，这样可以引用更多的blocks，也就是multi-level index。ext2,ext3等文件系统，都使用了muti-level index; xfs,ext4使用了extents。

另外一种方案是使用extents, 在inode里保存一个（地址，length）结构的数据，表示从某个block开始连续的length个block的大block, 这样我们可以存储多个extents在inode里，同样可以指向一个大文件。(extents类似内存管理里的segments)

### directory
Unix中一切皆文件，目录和文件一样，使用data blocks存储内容，内容的格式其实是一个list(inum, name)的形式，在inode里保存了type以区别其他文件格式。也有使用B-tree来存储目录的，比如XFS,这样操作起来效率比list更高。

### free space management
剩余空间追踪对于文件系统来说非常重要，因为它是分配空间的前提。vsfs使用简单的bitmap来追踪剩余空间（即可用的data blocks）。还有一些更高级的管理方法，一种是在Super Block中保存一个free list指针头，将可用的空间链在一个链表里。还有一种方法是利用B-tree结构来保存free list(XFS文件系统的用法)

### 读取文件
open(filename, 'r'):

根目录的inum是已知的，根据根目录递归遍历到指定文件，获取inum,进而将inode内容读取到内存中，做权限检查，并且分配一个fd到进程打开文件列表，并且返回fd给用户，fd通常是一个int值。

read():

根据inode内容，找到对应的数据block,并且进行读取，修改last update时间，更新进程打开文件的offset等。

### 写文件
这里不细说了，可以基于存储布局和读取文件的过程去想象。如果是创建一个新文件并且写入，这个是最复杂的。首先需要把文件创建出来，主要是inode分配，读取inode bitmap, 设置inode bitmap, 写入inode内容，读取data bitmap, 设置data bitmap, 更新inode, 写入数据，更新timestamp。

### io buffer
需要了解的是，文件系统的读写，现代操作系统都有缓存的机制。一些应用不希望使用buffer机制，所以调用fsync(),或者使用Direct I/O接口，或者直接使用raw disk的接口。

### 参考
[ostep filesytem implementation](http://www.cs.wisc.edu/~remzi/OSTEP/file-implementation.pdf)
