/*:
 **DISCLAIMER**
 
 This playground uses ARKit so it requires an iPad that is compatible. Also, this playground is designed such that the playground's screen's orientation is portrait, but any orientation will work.
 
 ### Introduction
 **Hello!** Welcome to ARtist. Have you ever wanted to draw in 3D? Well, now you can! Everything you draw in this playground is anchored to its location in space so you can walk around you drawings and view them from all angles!
 
 ![Logo](logo_small.png)
 
 This playground has a lot of cool features but first, you need to learn how to draw in 3D. After running the code, you will see 6 buttons. Don't worry, they are super simple to use!
 
 The **paint** button, the one in the center, is your magic button. Whenever you want to draw, just hold down the button! Move your iPad around to draw the same way you would a pen. If you want to stop drawing, just let go of the button. You can press and release whenever you'd like!
 
 The **reset** button, the one in the bottom left, will clear what you have drawn and allow you to start over.
 
 The three **colored** buttons on the bottom right will change what color you are drawing with.
 
 Finally, the **save** button, the one in the top right, will take a screenshot of whatever you are currently looking at and save it to your camera roll!
 
 And thats it, it's that simple! Once you've finished your masterpiece and got the hang of drawing, go to the [next](@next) page for a surprise!
 */

//#-hidden-code
import PlaygroundSupport
import UIKit

let viewController = DrawController()

PlaygroundPage.current.liveView = viewController
PlaygroundPage.current.needsIndefiniteExecution = true
//#-end-hidden-code
