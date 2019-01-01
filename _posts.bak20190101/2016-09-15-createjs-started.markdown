---
layout: post
title: get started with createjs chapter 1 notes
category: dev 
---

Firstly, chapter 1 show us pain points of animation development with raw H5 Canvas API. EaselJs lib is about to 
solve this pain. EaselJs provides us with elegent way to do Canvas management. EaselJs can free your head from much
trivial works, and make u focus on the game logic.

### get a taste of EaselJS
```
function drawButterflies() {
        var imgPath = 'xxx/xx.png';
        bf1 = new createjs.Bitmap(imgPath)
        bf1.x = 200;
        bf1.y = 400;
        state.addChild(bf1);
        stage.update();
        setTimeout(moveBf, 1000);
}

function moveBf() {
        bf1.y += 200;
        stage.update();
}
```
we have a programming model of operating Canvas graphics. First, we need to create a stage.
then we prepare our elements. we add these elements onto our stage. We update the stage, change elements' properties,
and loop this process.
All elements on stage are managed by a form of a tree, much easy to understand.

### how to implement overlap graphics?
In web front-end developing area, we can use z-index to control layer relations between two images. But how can we 
control layers in EaselJs?
```
stage.swapChildren(bf1, bf2)
```

### EaselJS API intro
createjs is a global js object acts as a namespace. Under this namespace, createjs defines many classes, 
like Stage Ticker Text Shape and so on.

### TweenJS Intro
TweenJS is used for animation.
```
createjs.Tween.get(bf1).to({y: bf1.y + 200}, 1000);
```
The basic steps are grab the target object, define the target state and interval, then done!
createjs.Tween is a static class. Ok, so simple, isn't it?

TweenJS predefines some effects we saw in Microsoft Office PPT, like ease in/ease out, bouncing and so on.
```
createjs.Tween.get(bf1).to({y: bf1.y + 200}, 1000, createjs.Ease.QuadOut)
```
There are two important methods of TweenJs, call and wait. "wait" is used for waiting for a while and then do the 
specific animation. "call" is something like animation completed hook.
By default, the hook func is scoped by target, but we can change that:

```
var Game = {
        score: 0,
        init: function() {
                this.drawButterflies();
        },
        drawButterflies: function() {
                        var imgPath = 'images/butterfly.jpg';
                        var butterfly = new createjs.Bitmap(imgPath);
                        stage.addChild(butterfly);
                        createjs.Tween.get(butterfly).to({y:100}, 1000).call(this.butterflyDone, [butterfly], this);
        },
        butterflyDone: function(butterfly) {
                stage.removeChild(butterfly);
                this.score += 10;
                this.gameOver();
        },
        gameOver: function() {
                alert("score:" + this.score);
        }
}
```
call has three arguments, the first one is the callback function, the second is an array of arguments for this callback function, the third is context.

### SoundJS Intro
```
createjs.Sound.registerSound("boom.mp3", "boom", 5);
var boom = createjs.Sound.play("boom");
```
When you want to use a audio file, you should first register this sound with a reference id, then play it. 
SoundJs predefines some events which you can use:
```
mySound.addEventListener("complete", function(mySound) {
        alert("sound has finished.");
});
```
We have several ways of audio playing methods, we call
plugins, fallback can be used to audio playing.

```
createjs.FlashPlugin.BASE_PATH = '../plugins';
createjs.Sound.registerPlugins([createjs.FlashPlugin]);
```
It seems Ease effects are implemented by Plugins. But don't need to be registered.

### PreloadJs Intro
PreloadJS is very straightforward, which is centered on LoadQueue class.
```
var queue = new createjs.LoadQueue();
queue.installPlugin(createjs.Sound);
queue.addEventListener("complete", onComplete);
queue.loadManifest([
        {id: "butterfly", src: "/img/butterfly.png"},
        {id: "poof", src: "/snd/poof.mp3"}
]);
function onComplete() {
        alert("all files loaded.");
}
```


### references
[EaselJs API Doc](http://createjs.cc/easeljs/docs/modules/EaselJS.html)

