---
layout: post
title: Vim Cheat Sheet
category: ops 
---

### 替换
```
%s/src_str/tgt_str/g
```

### 二进制文件查看
```
vim -b file
:%!xxd

# 修改存盘
:%!xxd -r
:wq
```

### 粘贴/复制
```
yy # copy one line
p # paste
v y p # copy multiple lines and paste
```

### 跳转/搜索
```
/pattern # 向下搜索
n # 匹配下一个
?pattern # 向上搜索
gg # 回第一行
G # 到最后一行
:line_no # 到某一行
```

### 黏贴冲突
如果vim使用了一些智能缩进/自动补全等等高级特性，那么在黏贴一些从外部进入的文件，可能就会有问题。这个时候
可以使用:set paste, 进入paste模式，再黏贴；黏贴完毕，使用:set nopaste进行还原。

### vim+ctags+cscope
具体的安装就不说了。ctags可以用来在源码中进行标识的跳转，cscope可以全局搜索。
```
# 切换到源码目录下（根目录)
ctags -R
cscope -Rbkq
# 修改vim配置

set tags=/path/to/tags;


if has("cscope")
    set cscopetag   " 使支持用 Ctrl+]  和 Ctrl+t 快捷键在代码间跳来跳去
    " check cscope for definition of a symbol before checking ctags:
    " set to 1 if you want the reverse search order.
    set csto=1

     " add any cscope database in current directory
    if filereadable("cscope.out")
         cs add cscope.out
     " else add the database pointed to by environment variable
    elseif $CSCOPE_DB !=""
         cs add $CSCOPE_DB
    endif

     " show msg when any other cscope db added
    set cscopeverbose

    nmap <C-/>s :cs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-/>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-/>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-/>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-/>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-/>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-/>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-/>d :cs find d <C-R>=expand("<cword>")<CR><CR>
endif
```

使用方法：

```
# 跳转到函数定义处
Ctrl + ] 
# 跳回
Ctrl + o/t
# 查询某个函数出现的文件
:cs find s {function}

# 查询某个函数定义的地方
:cs find g {function}

# 查询某个函数，在哪些地方被调用了
:cs find c {function}

```


