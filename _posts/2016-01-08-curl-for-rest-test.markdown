---
layout: post
title: 使用curl测试RESTful接口
category: ops
---


#### curl支持的url模式
```
http://site.{one, two, three}.com
ftp://test.com/file[001-100].txt
```

#### curl指定协议以及版本
curl支持很多种协议，不仅仅是http。猜测curl是通过url的前缀来判断使用何种协议，http开头即为http协议，ftp开头即为ftp协议。而对于http协议来说，是有多个版本的，包括1.0, 1.1, 2.0等，默认采用1.1。
```
--http1.0
--http1.1
--http2.0
```

#### curl发送payload
```
-d 
```

#### curl发送Header键值对
```
-H "Content-Type: application/json"
```

#### curl响应结果输出到文件
```
-o out.txt
```


#### curl不输出进度以及报错
```
-s
```

#### curl指定HTTP Method
```
-X POST
```
