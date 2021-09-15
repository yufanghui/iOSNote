这两天面试考察到了bounds,发现对这一块儿掌握的不是很好,对于bounds和anchorPoint,position的含义不是很清楚.今天把这个彻底搞懂吧.

bounds

概述

> The bounds rectangle, which describes the view’s location and size in its own coordinate system.
>
> //描述视图的位置和大小,在其自身的坐标系中.

讨论

> The default bounds origin is (0,0) and the size is the same as the size of the rectangle in the [`frame`](https://developer.apple.com/documentation/uikit/uiview/1622621-frame) property. 
>
> //默认的bounds的origin是(0,0).size和frame的size是一样的
>
> Changing the size portion of this rectangle grows or shrinks the view relative to its center point. 
>
> //更改size会让视图以它的圆心扩大或者缩小
>
> Changing the size also changes the size of the rectangle in the [`frame`](https://developer.apple.com/documentation/uikit/uiview/1622621-frame) property to match.
>
> //改了bounds的size,frame的size也会跟着修改
>
> The coordinates of the bounds rectangle are always specified in points.
>
> //
>
> Changing the bounds rectangle automatically redisplays the view without calling its [`draw(_:)`](https://developer.apple.com/documentation/uikit/uiview/1622529-draw) method. 
>
> //修改bounds会自动重新显示视图,而不需要调用draw方法
>
> If you want UIKit to call the [`draw(_:)`](https://developer.apple.com/documentation/uikit/uiview/1622529-draw) method, set the [`contentMode`](https://developer.apple.com/documentation/uikit/uiview/1622619-contentmode) property to [`UIView.ContentMode.redraw`](https://developer.apple.com/documentation/uikit/uiview/contentmode/redraw).
>
> //如果你想UIKit调用draw方法,设置[`contentMode`](https://developer.apple.com/documentation/uikit/uiview/1622619-contentmode) 的属性为[`UIView.ContentMode.redraw`](https://developer.apple.com/documentation/uikit/uiview/contentmode/redraw).
>
> Changes to this property can be animated.
>
> //修改这个属性,可以使用动画

总结下:

- bounds的origin是(0,0)
- 
