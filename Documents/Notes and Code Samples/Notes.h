//
//  Notes.h
//  echoprint
//
//  Created by Sanjay Jain on 6/6/14.
//
//

#import <Foundation/Foundation.h>

@interface Notes : NSObject

// View Controller Lifecycle ------------------------------------------------------------

// instantiated from storyboard

- (void)awakeFromNib
{
	// sent to all objects that come out of storyboard
	// happens before outlets are set (before MVC is loaded)
	// last resort for initialization code
	
	// anything in controllers init method must go here
	// (init methods not called on storyboard objects)
}

// outlets are set

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // good place for initialization code
    // geometry of view not set yet
}

// when geometry is determined/changes... 
//	viewWillLayoutSubviews and viewDidLayoutSubviews are called

- (void)viewWillAppear:(BOOL)animated
{
	// view is loaded only once
    // but many appear/disappear several times
    
    // do things here if something changes in MVC
    // while off-screen
    
    // okay to do geometry related operations
    // (but not best place)
    
    // sometimes, do expensive operations here
    // instead of viewDidLoad
}

- (void)viewWillDisappear:(BOOL)animated
{
    // this is where you put "remember whats
    // going on" and cleanup code
}

- (void)viewDidDisappear
- (void)didReceiveMemoryWarning
// -------------------------------------------------------------------------------------

// Protocols ---------------------------------------------------------------------------

id <MyProtocol> obj

Declaring a @protocol
- like @interface, but no @implementation
- method declarations
- a class implementing a protocol must implement methods
	- @required, @optional keywords

main use: delegates and datasources

// -------------------------------------------------------------------------------------

// UIView Animation --------------------------------------------------------------------

properties that can be animated: frame, transform, alpha

animation done with UIView class method that takes animation parameters and 
animation block as arguments

+ (void)animateWithDuration:...

// -------------------------------------------------------------------------------------

// UITableView

Subclass UITableViewController to create your own controller file
UITableViewController automatically sets itself as delegate and datasource of UITableView

@end
