##Making Friends with Value Types

This is my attempt to wrap my head around the concepts in Andy Matuschak's talk ["Controlling Complexity in Swift — or — Making Friends with Value Types"](https://realm.io/news/andy-matuschak-controlling-complexity/). He presents an interesting two layered approach to setting out your program with a thin imperative shell and a fat functional core. Sounds good but I'm struggling to really make sense of it. As a result I decided to try and flesh out his example in a playground. This is the result. 

Another article from Andy that tackles the same concept. [A Warm Welcome to Structs and Value Types](http://www.objc.io/issue-16/swift-classes-vs-structs.html)

As a side note, this is just my attempt to better understand the concepts presented by Andy Matuschak. I may be way off in many areas. Any corrections are welcome. 

###Yet to do

    // smooth touch sample curves
    extension TouchSample {
        static func smoothTouchSamples(samples: [TouchSample]) -> [TouchSample]
    }

- At what point do you create a new drawingAction? Needs to happen when a new touch gesture is started which is identified via data in UITouch. I see a couple of options
	- When a UITouch with a phase of Began comes in you create a new drawing action in handleTouch in the canvasController (class, identity). This is what is done above.
	- Push the step down a layer by creating a createNewDrawingAction function in the Drawing struct. (still activated in the layer above when the UITouch is identified)
	- Add a phase property to TouchSample so that this can then be detected in DrawingAction?

- Where should the current Tool be stored? We need to be able to select which tool is used for each drawing action. I'm assuming this will happen on creation of the DrawingAction primarily. Should there be a currentTool in the canvasController?
