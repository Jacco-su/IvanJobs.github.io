---
layout: post
title: 使用Python inotify监控文件变化
category: python
---
### 安装
```
sudo pip install inotify
```

### 编写代码监控文件内容更新
```
#!/usr/bin/env python

import os
import inotify.adapters

i = inotify.adapters.Inotify()

i.add_watch('./pepper/note')

for event in i.event_gen():
    if event is not None:
        os.system('deploy')

```


### daemon化运行py脚本
```
nohup python some.py &
```

### 参考
[Using inotify to watch for directory changes from Python](http://the.randomengineer.com/2015/04/24/using-inotify-to-watch-for-directory-changes-from-python/)
