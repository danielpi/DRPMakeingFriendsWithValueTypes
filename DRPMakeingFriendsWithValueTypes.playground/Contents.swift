//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"


struct Drawing {
    var actions: [DrawingAction]
    
    mutating func appendTouchSample(sample: TouchSample) {
        if let lastAction = actions.last {
            var action = lastAction
            //action.appendTouchSample(sample)
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
    
    /*
    mutating func appendTouchSample(sample: TouchSample) {
        samples = samples + [sample]
    }
    */
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



let canvasController = CanvasController()



let now = NSDate(timeIntervalSinceNow: 0)
let timestamp = now.timeIntervalSince1970
let a = TouchSample(x: 0.0, y: 0.0, timestamp:timestamp)
let b = TouchSample(x: 10, y: 10, timestamp:timestamp + 0.1)
let c = TouchSample(x: 20, y: -20, timestamp:timestamp + 0.2)
let d = TouchSample(x: 30, y: 30, timestamp:timestamp + 0.3)
let e = TouchSample(x: 40, y: -40, timestamp:timestamp + 0.4)

var drawingAction = DrawingAction(samples: [a,b,c,d,e], tool: DrawingAction.Tool.Pencil(color: UIColor.lightGrayColor()))
let drawingActionInitial = drawingAction
canvasController.currentDrawing.actions += [drawingAction]


let f = TouchSample(x: 50, y: 50, timestamp:timestamp + 0.5)
drawingAction.samples += [f]

drawingActionInitial.samples.count
drawingAction.samples.count

canvasController.currentDrawing.appendTouchSample(f)


let velocities = TouchSample.estimateVelocities(drawingAction.samples)


var pencil = PencilBrush()
pencil.lineWidth = 1.0
pencil.pathForDrawingAction(drawingAction)



//canvasController.currentDrawing = drawingAction

/*
// estimate touch velocity
extension TouchSample {
    static func estimateVelocities(samples: [TouchSample])
        -> [CGPoint]
}

// smooth touch sample curves
extension TouchSample {
    static func smoothTouchSamples(samples: [TouchSample]) -> [TouchSample]
}

// compute stroke geometry
struct PencilBrush {
    func pathForDrawingAction(action: DrawingAction)
        -> UIBezierPath
}

// incorporate touch into drawing (+ update state)
extension Drawing {
    mutating func appendTouchSample(sample: TouchSample)
}
*/
