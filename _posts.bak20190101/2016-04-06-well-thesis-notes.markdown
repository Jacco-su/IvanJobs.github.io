---
layout: post
title: Ceph论文阅读笔记
category: dev 
---

### NFS
Traditional solutions, exemplified by NFS [72], provide a
straightforward model in which a server exports a file system hierarchy that clients can map into
their local name space.

### XFS
As with most commonly used alternatives, XFS maintains an on-disk journal
file that it uses to log metadata updates that it is about to perform. In the event of a failure,
the journal can be read to ensure that updates were successfully and correctly applied, or clean
up any partially applied updates. Although journals come with a performance penalty—disks
have to frequently reposition themselves to append to the journal, and each metadata update is
written to disk twice—they avoid the need for more costly consistency checks during failure
recovery (which are increasingly expensive as file systems scale).

### EBOFS
The WAFL file system [40], for example, uses a
copy-on-write approach when update the hierarchical metadata structures, writing all new data
to unallocated regions of disk, such that changes are committed by simply updating a pointer to
the root tree node. WAFL also maintains a journal-like structure, but does so only to preserve
update durability between commits, not to maintain file system consistency. A similar technique
is used by EBOFS, the object-storage component of Ceph (see Chapter 7).

### NAS
Centralizing storage has facilitated the creation
of specialized, high-performance storage systems and popularized so-called NAS—network
attached storage.

### SAN
Recognizing that most file I/O in inherently parallel—that is, I/O to different files is
unrelated semantically—most recent “cluster” file systems are based on the basic idea of shared
access to underlying storage devices. So-called SAN—storage area network—file systems are
based on hard disks or RAID controllers communicating via a fibre channel (or similar) network,
allowing any connected host to issue commands to any connected disk.

### CRUSH
The data distribution policy is defined in terms of placement
rules that specify how many replica targets are chosen from the cluster and what restrictions
are imposed on replica placement.

The cluster map is composed of devices and buckets, both of which have numerical
identifiers and weight values associated with them. Buckets can contain any number of devices
or other buckets, allowing them to form interior nodes in a storage hierarchy in which devices
are always at the leaves. Storage devices are assigned weights by the administrator to control
the relative amount of data they are responsible for storing.

In contrast
to conventional hashing techniques, in which any change in the number of target bins (devices)
results in a massive reshuffling of bin contents, CRUSH is based on four different bucket types,
each with a different selection algorithm to address data movement resulting from the addition
or removal of devices and overall computational complexity.

By reflecting the underlying physical organization of the installation, CRUSH can model—
and thereby address—potential sources of correlated device failures. Typical sources include
physical proximity, a shared power source, and a shared network.

CRUSH is based on a wide variety of design goals including a balanced, weighted
distribution among heterogeneous storage devices, minimal data movement due to the addition
or removal of storage (including individual disk failures), improved system reliability through
the separation of replicas across failure domains, and a flexible cluster description and rule system
for describing available storage and distributing data.


### Recovery
The recovery strategy in RADOS is motivated by the observation that I/O is most
often limited by read (and not write) throughput.


### 参考
[weil-thesis](http://ceph.com/papers/weil-thesis.pdf)
