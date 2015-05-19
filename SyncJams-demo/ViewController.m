//
//  ViewController.m
//  SyncJams-demo
//
//  Created by Dan Wilcox on 5/9/15.
//  Copyright (c) 2015 puredata. All rights reserved.
//

#import "ViewController.h"

#import "PdFile.h"
#import "XYDragControl.h"

@interface ViewController ()

@property (strong, nonatomic) PdFile *patch;

// gui elements
@property (weak, nonatomic) IBOutlet UISlider *myslider;      // range in IB
@property (weak, nonatomic) IBOutlet UISlider *tickDivSlider; // range in IB
@property (weak, nonatomic) IBOutlet UISlider *bpmSlider;     // range in IB

@property (weak, nonatomic) IBOutlet UISwitch *mytoggle1; // 0-1 (BOOL)

@property (weak, nonatomic) IBOutlet UILabel *changeBPMLabel;
@property (weak, nonatomic) IBOutlet UILabel *changeTickDivLabel;
@property (weak, nonatomic) IBOutlet UILabel *changeMySliderLabel;


@property (weak, nonatomic) IBOutlet UILabel *netNodeLabel; // show current node-id
@property (weak, nonatomic) IBOutlet UILabel *netBPMLabel; // show current bpm
@property (weak, nonatomic) IBOutlet UILabel *netTickLabel; // show current tick count
@property (weak, nonatomic) IBOutlet UILabel *netSliderValueLabel;


@property (weak, nonatomic) IBOutlet UIView *blinkView;
@property (weak, nonatomic) IBOutlet UIView *blinkView2;

@property (weak, nonatomic) IBOutlet XYDragControl *xyControl;
@property (nonatomic) BOOL isSynthOne;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	// receive messages from pd
	[PdBase setDelegate:self];
	[PdBase setMidiDelegate:self]; // for midi too
	
	// open patch
	self.patch = [PdFile openFileNamed:@"SyncJams-demo.pd"
								  path:[NSString stringWithFormat:@"%@/pd", [[NSBundle mainBundle] bundlePath]]];
	
	// receive SyncJams gui update messages
	[PdBase subscribe:@"/myslider/1/r"];
	[PdBase subscribe:@"/myslider/2/r"];
	[PdBase subscribe:@"/mytoggle/1/r"];
    [PdBase subscribe:@"netSlidervalue"];
	
	// receive node-id & current tick
	[PdBase subscribe:@"node-id"];
	[PdBase subscribe:@"bpm"];
	[PdBase subscribe:@"tick"];
    [PdBase subscribe:@"playBang"];
    
    [_xyControl setupXYView];
    _xyControl.delegate = self;
    [PdBase sendFloat: 1 toReceiver:@"syn-mix"];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - UI Interaction

- (IBAction)sliderChanged:(id)sender {
    if(sender == self.bpmSlider) {
        //[PdBase sendFloat:self.myslider2.value toReceiver:@"/myslider/2"];
        [PdBase sendFloat:self.bpmSlider.value toReceiver:@"changeBPM"];
        _changeBPMLabel.text = [NSString stringWithFormat:@"%i",(int)self.bpmSlider.value];
        _changeBPMLabel.alpha = 1;
        [UIView animateWithDuration:1
                              delay:3
                            options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _changeBPMLabel.alpha = 0;
        } completion:^(BOOL finished) {
            //
        }];
    }
	if(sender == self.tickDivSlider) {
		//[PdBase sendFloat:self.myslider1.value toReceiver:@"/myslider/1"];
        [PdBase sendFloat: (int)self.tickDivSlider.value toReceiver:@"tick-divide"];
        _changeTickDivLabel.text = [NSString stringWithFormat:@"%i",(int)self.tickDivSlider.value];
	}
    if(sender == self.myslider) {
        [PdBase sendFloat:self.myslider.value toReceiver:@"changeSlider"];
        _changeMySliderLabel.text = [NSString stringWithFormat:@"%i",(int)self.myslider.value];
    }
    
}

- (IBAction)switchChanged:(id)sender {
	if(sender == self.mytoggle1) {
		[PdBase sendFloat:(float)self.mytoggle1.isOn toReceiver:@"/mytoggle/1"];
	}
}

#pragma mark - PdReceiverDelegate

- (void)receivePrint:(NSString *)message {
	NSLog(@"%@", message);
}

- (void)receiveBangFromSource:(NSString *)source {
    if([source isEqualToString:@"playBang"]) {
        [self triggerUpdate];
        return;
    }
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
    
	// receieve floats for each gui element
    if([source isEqualToString:@"/myslider"]) {
        self.netSliderValueLabel.text = [NSString stringWithFormat:@"%d", (int)received];
    }
    // node-id sometimes comes as a float, sometimes as a list
    else if([source isEqualToString:@"node-id"]) {
        self.netNodeLabel.text = [NSString stringWithFormat:@"%d", (int)received];
    }
    
    // current bpm value
    else if([source isEqualToString:@"bpm"]) {
        self.netBPMLabel.text = [NSString stringWithFormat:@"%d", (int)received];
    }
    
    // current tick value
    else if([source isEqualToString:@"tick"]) {
        self.netTickLabel.text = [NSString stringWithFormat:@"%d", (int)received];
        [self triggerUpdate2];
    }
    
    
    /*
	if([source isEqualToString:@"/myslider/1/r"]) {
		self.myslider_2.value = received;
	}
	else if([source isEqualToString:@"/myslider/2/r"]) {
		self.myslider_1.value = received;
	}
	else if([source isEqualToString:@"/mytoggle/1/r"]) {
		self.mytoggle1.on = received;
	}
     */

	if (![source isEqualToString:@"tick"]) NSLog(@"Float from %@: %f", source, received);
}




- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
	NSLog(@"Symbol from %@: %@", source, symbol);
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
	
	// node-id sometimes comes as a float, sometimes as a list
	if([source isEqualToString:@"node-id"] && list.count > 0 && [list.firstObject isKindOfClass:[NSNumber class]]) {
		self.netNodeLabel.text = [NSString stringWithFormat:@"%@", list.firstObject];
		return;
	}
	
	NSLog(@"List from %@", source);
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
	
	// receive set messages for each gui element
	if([message isEqualToString:@"set"] && arguments.count > 1 && [arguments.firstObject isKindOfClass:[NSNumber class]]) {
		if([source isEqualToString:@"/myslider/1/r"]) {
			self.tickDivSlider.value = [arguments[0] floatValue];
		}
		else if([source isEqualToString:@"/myslider/2/r"]) {
			self.bpmSlider.value = [arguments[0] floatValue];
		}
		else if([source isEqualToString:@"/mytoggle/1/r"]) {
			self.mytoggle1.on = [arguments[0] boolValue];
		}
	}
	
	NSLog(@"Message to %@ from %@", message, source);
}

#pragma mark - PdMidiReceiverDelegate

- (void)receiveNoteOn:(int)pitch withVelocity:(int)velocity forChannel:(int)channel{
	NSLog(@"NoteOn: %d %d %d", channel, pitch, velocity);
}

- (void)receiveControlChange:(int)value forController:(int)controller forChannel:(int)channel{
	NSLog(@"Control Change: %d %d %d", channel, controller, value);
}

- (void)receiveProgramChange:(int)value forChannel:(int)channel{
	NSLog(@"Program Change: %d %d", channel, value);
}

- (void)receivePitchBend:(int)value forChannel:(int)channel{
	NSLog(@"Pitch Bend: %d %d", channel, value);
}

- (void)receiveAftertouch:(int)value forChannel:(int)channel{
	NSLog(@"Aftertouch: %d %d", channel, value);
}

- (void)receivePolyAftertouch:(int)value forPitch:(int)pitch forChannel:(int)channel{
	NSLog(@"Poly Aftertouch: %d %d %d", channel, pitch, value);
}

- (void)receiveMidiByte:(int)byte forPort:(int)port{
	NSLog(@"Midi Byte: %d 0x%X", port, byte);
}

#pragma mark - UI Update

- (void) triggerUpdate
{
    _blinkView.alpha = 1;
    [UIView animateWithDuration:0.20 animations:^{
        _blinkView.alpha = 0;
    } completion:^(BOOL finished) {
        //
    }];
}

- (void) triggerUpdate2
{
    _blinkView2.alpha = 1;
    [UIView animateWithDuration:0.20 animations:^{
        _blinkView2.alpha = 0;
    } completion:^(BOOL finished) {
        //
    }];
}

#pragma mark - XY GUI Update

- (void) didPanPosition: (CGPoint)point sender:(id)sender
{
    [PdBase sendFloat:(1.0f-point.y) toReceiver:@"syn-pitch"];
    [PdBase sendFloat:point.x toReceiver:@"syn-duration"];
    _xyControl.dragger.alpha = 1;
}

- (void) didPanEnd: (id)sender
{
    _xyControl.dragger.alpha = 0;
}

- (void) didDoubleTapXY: (id)sender
{
    _isSynthOne = !_isSynthOne;
    [PdBase sendFloat: (int)_isSynthOne toReceiver:@"syn-mix"];
}


@end
