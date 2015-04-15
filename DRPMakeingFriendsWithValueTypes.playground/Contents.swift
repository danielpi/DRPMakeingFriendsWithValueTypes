import UIKit

// This playground is my attempt to flesh out some example code from Andy Matuschak's talk titled "Controlling Complexity in Swift — or — Making Friends with Value Types". It can be found over here https://realm.io/news/andy-matuschak-controlling-complexity/ and I highly recommend watching it.

// Whilst watching the talk I had difficulty wrapping my head around the concepts and seeing how they should be applied. So as a first step towards understanding I have tried to flesh out the example code that is used in the talk.

// One of the key points in the talk is the three I's of value types. 

// Value types are Inert.
// It’s pretty hard to make a value type that behaves, especially over time. It’s typically inert, a hunk of data like the spreadsheet, storing data and exposing methods that perform computations on that data. What tha tmeans is that the control flow is strictly controlled by the one owener of that value type. That makes it vastly easier to reason about code that will only be invoked by one caller.

// Value types are Isolated.
// Reference types create implicit dependencies, or dependencies in the application structure that can’t be seen.

// Value types are Interchangable.
//  Every time you assign a value to a new variable, that value is copied, and so all of those copies are completely interchangeable. If they have the same data in them, you cannot tell the difference between them. This means that you can safely store a value that’s been passed to you. Interchangeability means that it doesn’t matter how a value was constructed, as long as it compares equal via equals equals.


struct Drawing {
    var actions: [DrawingAction]
    
    mutating func appendTouchSample(sample: TouchSample) {
        if let lastAction = actions.last {
            var action = lastAction
            action.samples += [sample]
            
            actions.removeLast()
            actions = actions + [action]
        } else {
            let drawingAction = DrawingAction(samples: [sample], tool: DrawingAction.Tool.Pencil(color: UIColor.blackColor()))
            actions += [drawingAction]
        }
    }
}

struct DrawingAction {
    var samples: [TouchSample]
    var tool: Tool
    
    enum Tool {
        case Pencil(color: UIColor)
        case Eraser(width: CGFloat)
    }
}

struct TouchSample {
    var location: CGPoint
    var timestamp: NSTimeInterval
    
    init(_ touch: UITouch) {
        self.location = touch.locationInView(touch.view)
        self.timestamp =  touch.timestamp
    }
    init(location: CGPoint, timestamp: NSTimeInterval) {
        self.location = location
        self.timestamp = timestamp
    }
    init(x: Double, y: Double, timestamp: NSTimeInterval) {
        self.location = CGPoint(x: x, y: y)
        self.timestamp = timestamp
    }
}


class CanvasController {
    var currentDrawing: Drawing
    
    init() {
        currentDrawing = Drawing(actions: [])
    }
    
    func handleTouch(touch: UITouch) {
        let touchSample = TouchSample(touch)
        
        if let existingDrawingAction = currentDrawing.actions.last {
            if touch.phase != .Began {
                // If there is an existing drawing action and the UITouch isn't new we can append to the most recent drawing.
                currentDrawing.appendTouchSample(touchSample)
            }
        } else {
            // Otherwise we have to create a new drawing action
            let drawingAction = DrawingAction(samples: [touchSample], tool: DrawingAction.Tool.Pencil(color: UIColor.blackColor()))
            currentDrawing = Drawing(actions: currentDrawing.actions + [drawingAction])
        }
    }
}


extension TouchSample {
    static func estimateVelocities(samples: [TouchSample]) -> [CGPoint] {
        var velocities: [CGPoint] = []
        
        switch samples.count {
        case 0:
            velocities = []
        case 1:
            velocities.append(CGPoint(x: 0, y: 0))
        case 2:
            velocities.append(TouchSample.estimateVelocity(samples[0], samples[1]))
            velocities.append(TouchSample.estimateVelocity(samples[0], samples[1]))
        default:
            velocities.append(TouchSample.estimateVelocity(samples[0], samples[1]))
            for (ind, value) in enumerate(samples[1..<(samples.count - 1)]) {
                let index = ind + 1
                velocities.append(TouchSample.estimateVelocity(samples[index - 1], samples[index], samples[index + 1]))
            }
            velocities.append(TouchSample.estimateVelocity(samples[samples.count - 2], samples[samples.count-1]))
        }
        
        return velocities
    }
    
    static func estimateVelocity(a: TouchSample, _ b: TouchSample) -> CGPoint {
        let deltaX: Double = Double(b.location.x - a.location.x)
        let deltaY: Double = Double(b.location.y - a.location.y)
        let deltaTime: Double = b.timestamp - a.timestamp
        return CGPoint(x: deltaX / deltaTime, y: deltaY / deltaTime)
    }
    
    static func estimateVelocity(a: TouchSample, _ b: TouchSample, _ c: TouchSample) -> CGPoint {
        let initialVel = estimateVelocity(a, b)
        let finalVel = estimateVelocity(b, c)
        return CGPoint(x:(initialVel.x + finalVel.x) / 2, y: (initialVel.y + finalVel.y) / 2)
    }

}

struct PencilBrush {
    var lineWidth: CGFloat = 2.0
    var lineColor: UIColor = UIColor.blackColor()
    
    func pathForDrawingAction(action: DrawingAction) -> UIBezierPath {
        var path = UIBezierPath()
        path.lineWidth = lineWidth
        
        // Linear interpolation
        path.moveToPoint(action.samples[0].location)
        for sample in action.samples {
            // This adds a line from the start point to itself.
            path.addLineToPoint(sample.location)
        }
        
        return path
    }
}


// This is the identity for our state
let canvasController = CanvasController()


// We can create a stream of data
let now = NSDate(timeIntervalSinceNow: 0)
let timestamp = now.timeIntervalSince1970
let a = TouchSample(x: 0.0, y: 0.0, timestamp:timestamp)
let b = TouchSample(x: 10, y: 10, timestamp:timestamp + 0.1)
let c = TouchSample(x: 20, y: -20, timestamp:timestamp + 0.2)
let d = TouchSample(x: 30, y: 30, timestamp:timestamp + 0.3)
let e = TouchSample(x: 40, y: -40, timestamp:timestamp + 0.4)

var drawingAction = DrawingAction(samples: [a,b,c,d,e], tool: DrawingAction.Tool.Pencil(color: UIColor.lightGrayColor()))


// Adding our stream of data to our state identity gives it a snapshot of our data.
canvasController.currentDrawing.actions += [drawingAction]


// We can then modify our data without the snapshot being affected
let f = TouchSample(x: 50, y: 50, timestamp:timestamp + 0.5)
drawingAction.samples += [f]

canvasController.currentDrawing.actions[0].samples.count
drawingAction.samples.count


// The stream of data can be passed around and used elsewhere without any risk of it being changed.
let velocities = TouchSample.estimateVelocities(drawingAction.samples)


var pencil = PencilBrush()
pencil.lineWidth = 1.0
pencil.pathForDrawingAction(canvasController.currentDrawing.actions[0])

// We can incorporate state and side effects by invoking methods on our identity.
canvasController.currentDrawing.appendTouchSample(f)
let g = TouchSample(x: 60, y: 0, timestamp:timestamp + 0.6)
canvasController.currentDrawing.appendTouchSample(g)

var pencil2 = pencil
pencil2.lineWidth = 2.0
pencil2.pathForDrawingAction(canvasController.currentDrawing.actions[0])






/*
Yet to do

// smooth touch sample curves
extension TouchSample {
    static func smoothTouchSamples(samples: [TouchSample]) -> [TouchSample]
}

At what point do you create a new drawingAction? Needs to happen when a new touch gesture is started which is identified via data in UITouch. I see a couple of options
- When a UITouch with a phase of Began comes in you create a new drawing action in handleTouch in the canvasController (class, identity). This is what is done above.
- Push the step down a layer by creating a createNewDrawingAction function in the Drawing struct. (still activated in the layer above when the UITouch is identified)
- Add a phase property to TouchSample so that this can then be detected in DrawingAction?

Where should the current Tool be stored? We need to be able to select which tool is used for each drawing action. I'm assuming this will happen on creation of the DrawingAction primarily. Should there be a currentTool in the canvasController?
*/
