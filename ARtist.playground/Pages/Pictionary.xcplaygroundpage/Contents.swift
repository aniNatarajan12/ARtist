/*:
 
 ## Pictionary
 Drawing in 3D is really cool right! Do you know what's even cooler? **3D Pictionary!** "Who am I playing?" with you might ask. Well... me!
 
 In this page, try drawing any single digit number (0-9) and I will guess what you drew!
 
 To make things more interesting, I'm gonna time you! You will have a countdown on the top of the screen and you have to have completed drawing your number by the time it runs out.
 
 When the timer ends, the paint button will change to a camera. Angle yourself so that the number approxiamtely fills up the entire screen and then press the button for a prediction. Neat right! Just press anywhere on the side to remove the prediction and hold the paint button to start drawing again!
 
 Oh and also, since I'm not perfect, I would really appreciate it if you drew the numbers with some of their extra feautres. For example, 1 instead of | and adding a dash along the 7.
 
 ### If you need more time,
 change the value of the variable below (it's in seconds).
 */
var time = 6

//: Click [here](@previous) if you want to go back to the previous page and do some free drawing!

//#-hidden-code
import PlaygroundSupport
import UIKit

let viewController = MLController()

viewController.totalTime = time

PlaygroundPage.current.liveView = viewController
PlaygroundPage.current.needsIndefiniteExecution = true
//#-end-hidden-code
