---
layout: post
title: MathQuill学习笔记
categories: math dev 
---

### 库引入
1. mathquill的css文件
2. jquery
3. mathquill的js文件

### 获取接口实例
库引入之后，我们就可以用一个mathquill的全局变量：MathQuill。
通过调用MathQuill.getInterface(2)获取最新的接口实例。
```
var MQ = MathQuill.getInterface(2) # 获取特定版本的接口
```



### 动态添加MathQuill节点
MathQuill的公式都是计算出来的，所以如果dom元素发生变化，需要重新计算：
```
var mathFieldSpan = $('<span>\\sqrt{2}</span>')
var mathField = MQ.MathField(mathFieldSpan[0])
mathFieldSpan.appendTo(document.body)
mathField.reflow()
```


### 公共接口

.el() => 返回root元素。

.html() => 返回公式的静态的html。

.latex() => 返回公式的latex表达式。

.latex(latex_expression) => 渲染传入的latex表达式。


### EditableField的方法
.focus() .blur() => 聚焦和失焦

.write('- 1') => 在当前光标点写入一些latex

.cmd('\\sqrt') => 在当前光标处或者选择区域写入latex命令

.revert() => 将MathQuillified的元素还原

.reflow() => 动态计算导致的重新渲染

.select() => 选择内容

.clearSelection() => 清除当前的选择

.moveTo{Left,Right,Dir}End() => 移动光标

.keystroke(keys) => 模拟键盘按键

.typedText(text) => 模拟字符输入，一个字符一个字符

### MathField的配置项
```
var el = $('<span>x^2</span>').appendTo('body');
var mathField = MQ.MathField(el[0], {
  spaceBehavesLikeTab: true,
  leftRightIntoCmdGoes: 'up',
  restrictMismatchedBrackets: true,
  sumStartsWithNEquals: true,
  supSubsRequireOperand: true,
  charsThatBreakOutOfSupSub: '+-=<>',
  autoSubscriptNumerals: true,
  autoCommands: 'pi theta sqrt sum',
  autoOperatorNames: 'sin cos etc',
  substituteTextarea: function() {
    return document.createElement('textarea');
  },
  handlers: {
    edit: function(mathField) { ... },
    upOutOf: function(mathField) { ... },
    moveOutOf: function(dir, mathField) { if (dir === MQ.L) ... else ... }
  }
});
```
使用.config({...}),来设置具体的配置项。全局默认配置项使用MQ.config({...})

### 事件支持
moveOutOf => 比如光标在最左边，这个时候按左键，就触发了moveOutOf事件，下面的类推。

deleteOutOf => 参考上面

selectOutOf => 参考上面

upOutOf => 参考上面

downOutOf => 参考上面

enter => 按enter键时触发

edit => 当发生内容变动时触发

### 修改颜色
如果要改变前景色，设置color的同时，再设置border-color。



### StaticMath() 和 MathField() 的差别
MQ.StaticMath()和MQ.MathField()的差别？一个是静态的，就是只做展示，不可以编辑；另一个则是可读可写的。


### MQ自身也是个函数
MQ函数传入的是一个dom对象，如果这个dom对象恰好被MathQuillified, 那么就返回MathQuill的API对象，如果不是，则返回null。

### MathQuill API 对象有唯一的标识符id
不管是通过MathField()、StaticMath()，还是通过MQ函数，获取的API对象，都包含一个id，相同的API对象id相同。

### MathQuill API 对象有一个data属性
可以自定义一些跟当前MathQuill对象相关的属性。

###  

### 参考
[MathQuill官网](http://mathquill.com/)

[Mathquill GitHub](https://github.com/mathquill/mathquill)


