---
layout: post
title: 数论学习笔记
---
### 整数分类
Integers:
<figure class="highlight"><pre class="mathquill-ivanjobs">\cdots-2, -1, 0, 1, 2, \cdots</pre></figure>

Whole Numbers:
<figure class="highlight"><pre class="mathquill-ivanjobs">0, 1, 2, \cdots</pre></figure>

Counting Numbers:
<figure class="highlight"><pre class="mathquill-ivanjobs">1, 2, 3, \cdots</pre></figure>

### 完全平方数
<figure class="highlight"><pre class="mathquill-ivanjobs">3^2 + 4^2 = 5^2</pre></figure>
<figure class="highlight"><pre class="mathquill-ivanjobs">5^2 + 12^2 = 13^2</pre></figure>
<figure class="highlight"><pre class="mathquill-ivanjobs">8^2 + 15^2 = 17^2</pre></figure>
<figure class="highlight"><pre class="mathquill-ivanjobs">7^2 + 24^2 = 25^2</pre></figure>
<figure class="highlight"><pre class="mathquill-ivanjobs">20^2 + 21^2 = 29^2</pre></figure>
<figure class="highlight"><pre class="mathquill-ivanjobs">12^2 + 35^2 = 37^2</pre></figure>
<figure class="highlight"><pre class="mathquill-ivanjobs">9^2 + 40^2 = 41^2</pre></figure>

### 整除推论
如果最后一个数字可以被2整除，那么整个整数可以被2整除。

如果最后两个数字可以被4整除，那么整个整数可以被4整除。

如果最后三个数字可以被8整除，那么整个整数可以被8整除。

如果各位数字之和可以被3整除，那么整个整数可以被3整除。

如果各位数字之和可以被9整除，那么整个整数可以被9整除。

### 欧几里得定理
欧几里得定理又叫“辗转相除法”，是求解最大公约数的有效方法。对于两个自然数a和b, gcd(a, b) = gcd(b, a % b).代码如下：
{% highlight cpp %}
int gcd(a, b) {
  while(b != 0) {
    int tmp = a % b;
    a = b;
    b = tmp;
  }
  return a;
}
{% endhighlight %}

### 扩展欧几里得定理
欧几里得定理是求两个自然数的最大公约数，gcd(a, b) = gcd(b, a % b);而扩展欧几里得是求一个tuple：
(s, t), a*s + b*t = gcd(a, b);
代码如下：
{% highlight cpp %}
template <class T>

T exgcd(T m, T n, T& x, T& y) {
  T x1, y1, x0, y0;
  x0 = 1; y0 = 0;
  x1 = 0; y1 = 1;
  x = 0; y = 1;
  T r = m % n;
  T q = (m - r) / n;
  while(r != 0) {
    x=x0-q*x1; y=y0-q*y1;
    x0=x1; y0=y1;
    x1=x; y1=y;
    m=n; n=r; r=m%n;
    q=(m-r)/n;
  }
  return n;
}
{% endhighlight %}

### 数论倒数
a相对于f的数论倒数为b，代表(a * b) % f = 1。现在有a和f, 要我们求b。代码如下：
{% highlight cpp %}
T invert(T e, T f) {
    T a = f, b = e, t1 = 0, t2 = 1;

    while (b != 0) {
        T t = a;
        a = b;
        T q = t / b;
        b = t % b;

        t = t1 - q * t2;
        t1 = t2;
        t2 = t;
    }

    if (t1 < 0) t1 += f;
    return t1;
}
{% endhighlight %}

### 中国剩余定理


### 参考
[Number Thoery Introduction](https://www.youtube.com/watch?v=FtztfI86pBY&list=PLr3WmPgPWZfX1HUpeyKkP6ir2wOFhqXMO)
