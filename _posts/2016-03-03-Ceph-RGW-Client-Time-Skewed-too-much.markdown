---
layout: post
title: 访问Ceph RGW失败 403 Forbidden问题 解决历程
category: dev 
---

以前的时候，写过一些测试Ceph RGW接口的脚本，比如[get user info](https://github.com/IvanJobs/play/blob/master/ceph/admin-ops/get_user_info.py), 今天执行的时候，Python脚本报错403 Forbidden，check了一段时间，还是没有找到问题。因为这个脚本上次用过，没有问题，过了一段时间到现在，突然就不行了，很奇怪。思忖良久之后，仍然没有找到问题所在，所以抱着试试看的心态，使用tcpdump进行抓包。

### 抓包
在RGW节点上，抓取关于客户端（172.16.138.23）的包。
```
sudo tcpdump host 172.16.138.23 -Xi  eth0 > tcpdump.log 
```
注意：选项X必须在i的前面，因为-i这个选项要带参数。

抓包结果：
```
14:57:30.462487 IP 172.16.138.23.49710 > ceph1.http: Flags [P.], seq 1:243, ack 1, win 259, length 242
        0x0000:  4500 011a 7c68 4000 3c06 5871 ac10 8a17  E...|h@.<.Xq....
        0x0010:  0ac0 281d c22e 0050 08fd f6b6 7ffe 2c49  ..(....P......,I
        0x0020:  5018 0103 7554 0000 4745 5420 2f61 646d  P...uT..GET./adm
        0x0030:  696e 2f75 7365 723f 7569 643d 656c 656d  in/user?uid=elem
        0x0040:  6520 4854 5450 2f31 2e31 0d0a 4163 6365  e.HTTP/1.1..Acce
        0x0050:  7074 2d45 6e63 6f64 696e 673a 2069 6465  pt-Encoding:.ide
        0x0060:  6e74 6974 790d 0a43 6f6e 6e65 6374 696f  ntity..Connectio
        0x0070:  6e3a 2063 6c6f 7365 0d0a 486f 7374 3a20  n:.close..Host:.
        0x0080:  3130 2e31 3932 2e34 302e 3239 0d0a 4175  10.192.40.29..Au
        0x0090:  7468 6f72 697a 6174 696f 6e3a 2041 5753  thorization:.AWS
        0x00a0:  205a 3245 544b 4334 5251 4654 5234 5842  .Z2ETKC4RQFTR4XB
        0x00b0:  5131 4137 323a 2b4c 536f 6856 5372 2f76  Q1A72:+LSohVSr/v
        0x00c0:  6358 304d 3353 3155 3475 742b 625a 6342  cX0M3S1U4ut+bZcB
        0x00d0:  553d 0d0a 5573 6572 2d41 6765 6e74 3a20  U=..User-Agent:.
        0x00e0:  5079 7468 6f6e 2d75 726c 6c69 622f 332e  Python-urllib/3.
        0x00f0:  340d 0a44 6174 653a 2054 6875 2c20 3033  4..Date:.Thu,.03
        0x0100:  204d 6172 2032 3031 3620 3036 3a33 373a  .Mar.2016.06:37:
        0x0110:  3134 2047 4d54 0d0a 0d0a                 14.GMT....

14:57:30.463589 IP ceph1.http > 172.16.138.23.49710: Flags [P.], seq 1:219, ack 243, win 237, length 218
        0x0000:  4500 0102 c77a 4000 4006 0977 0ac0 281d  E....z@.@..w..(.
        0x0010:  ac10 8a17 0050 c22e 7ffe 2c49 08fd f7a8  .....P....,I....
        0x0020:  5018 00ed 69f9 0000 4854 5450 2f31 2e31  P...i...HTTP/1.1
        0x0030:  2034 3033 2046 6f72 6269 6464 656e 0d0a  .403.Forbidden..
        0x0040:  4461 7465 3a20 5468 752c 2030 3320 4d61  Date:.Thu,.03.Ma
        0x0050:  7220 3230 3136 2030 363a 3537 3a33 3020  r.2016.06:57:30.
        0x0060:  474d 540d 0a53 6572 7665 723a 2041 7061  GMT..Server:.Apa
        0x0070:  6368 652f 322e 342e 3720 2855 6275 6e74  che/2.4.7.(Ubunt
        0x0080:  7529 0d0a 4163 6365 7074 2d52 616e 6765  u)..Accept-Range
        0x0090:  733a 2062 7974 6573 0d0a 436f 6e74 656e  s:.bytes..Conten
        0x00a0:  742d 4c65 6e67 7468 3a20 3331 0d0a 436f  t-Length:.31..Co
        0x00b0:  6e6e 6563 7469 6f6e 3a20 636c 6f73 650d  nnection:.close.
        0x00c0:  0a43 6f6e 7465 6e74 2d54 7970 653a 2061  .Content-Type:.a
        0x00d0:  7070 6c69 6361 7469 6f6e 2f6a 736f 6e0d  pplication/json.
        0x00e0:  0a0d 0a7b 2243 6f64 6522 3a22 5265 7175  ...{"Code":"Requ
        0x00f0:  6573 7454 696d 6554 6f6f 536b 6577 6564  estTimeTooSkewed
        0x0100:  227d                                     "}

```

意外收获，使用python脚本访问RGW只会返回403 Forbidden, 并不会给出具体的原因， 而是用抓包的方法，能够看到返回了错误描述RequestTimeTooSkewed！

### 解决
使用date命令，粗略比较了客户端和RGW服务器的时间，发现相差好几分钟，这种差别是不能容忍的，所以RGW返回403。使用ntpdate 命令同步一下客户端的时间，再次运行，问题轻松解决。

### 总结
抓包是一个必须熟练学习掌握的debug方法。


