//
//
//  Created by Oliver Greschke on 04.12.12.
//  Copyright (c) 2012 Oliver Greschke. All rights reserved.
//

#import "XYDragControl.h"

#define SIDELENGTH 25.0f

@implementation XYDragControl


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupXYView];
    }
    return self;
}



-(void) setupXYView
{
    self.backgroundColor = [UIColor clearColor];
    
    // fx-bg
    UIImageView *imgView=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width,self.frame.size.height)];
    UIImage *image = [UIImage imageNamed: @"fx-bg.png"];  // Just gave image name if Image in Xcode Project
    imgView.image=image;  // Now set that Image
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:imgView];
    
    // add description label
    self.horitontalLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width-210,10, 200, 20)];
    self.horitontalLabel.text = @"";
    self.horitontalLabel.font = [UIFont systemFontOfSize:18];
    self.horitontalLabel.textColor = [UIColor redColor];
    self.horitontalLabel.textAlignment = NSTextAlignmentRight;
    self.horitontalLabel.alpha = 0.4;
    [self addSubview:self.horitontalLabel];
    
    self.vertikalLabel = [[UILabel alloc] initWithFrame:CGRectMake(-80, self.frame.size.height-120,200, 20)];
    self.vertikalLabel.text = @"";
    self.vertikalLabel.font = [UIFont systemFontOfSize:16];
    self.vertikalLabel.textColor = [UIColor redColor];
    self.vertikalLabel.textAlignment = NSTextAlignmentRight;
    self.vertikalLabel.alpha = 0.4;
    [self.vertikalLabel setTransform:CGAffineTransformMakeRotation(+90* M_PI/180)];
    [self addSubview:self.vertikalLabel];
    
    CGRect dragRect = CGRectMake(0, 0, SIDELENGTH, SIDELENGTH);
    self.dragger = [[DraggerView alloc] initWithFrame:dragRect ];
    self.dragger.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    [self addSubview:self.dragger];
    [self.dragger setUserInteractionEnabled:NO];
    
    UIGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleFXPan:)];
    [self addGestureRecognizer:pan];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleFXTap:)];
    tap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tap];
    
    UITapGestureRecognizer *doubletap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleFXDoubleTap:)];
    doubletap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubletap];
    

    
    // Create a mask layer and the frame to determine what will be visible in the view.
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CGRect maskRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    // Create a path with the rectangle in it.
    // Set the path to the mask layer.
    CGPathRef path = CGPathCreateWithRoundedRect(maskRect, 5, 5, NULL);
    maskLayer.path = path;
    // Release the path since it's not covered by ARC.
    CGPathRelease(path);
    // Set the mask of the view.
    self.layer.mask = maskLayer;
    
}


- (void) handleFXPan: (UIPanGestureRecognizer *) gestureRecognizer
{
    
    CGPoint p = [gestureRecognizer locationInView:self];
    //NSLog(@"Touch x : %f y : %f", p.x, p.y);
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan || gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        
        if (p.x < 0) p.x = 0;
        else if (p.x > self.bounds.size.width)  p.x = self.bounds.size.width;
        if (p.y < 0) p.y = 0;
        else if (p.y > self.bounds.size.height) p.y = self.bounds.size.height;
        
        [self setDraggerPosition:p];
    }
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateEnded) {
        
        //NSLog(@"dragEnded......");
        [self.delegate didPanEnd:self];
    }
}



- (void) handleFXTap: (UITapGestureRecognizer *) gestureRecognizer
{
    //NSLog(@"handleFXDoubleTap - gestureRecognizer state ");
    
    CGPoint p = [gestureRecognizer locationInView:self];

    if (p.x < 0) p.x = 0;
    else if (p.x > self.bounds.size.width)  p.x = self.bounds.size.width;
    if (p.y < 0) p.y = 0;
    else if (p.y > self.bounds.size.height) p.y = self.bounds.size.height;
    
    [self setDraggerPosition:p];
    
    double delayInSeconds = 0.1f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //whatever you wanted to do here...
        [self.delegate didPanEnd:self];
    });
    
}


- (void) setDraggerPositionNormalized:(CGPoint) point
{
    CGPoint pointInView = CGPointMake(point.x*self.frame.size.width, point.y*self.frame.size.height);
    [self setDraggerPosition:pointInView];
}

- (void) setDraggerPosition:(CGPoint) point
{

    self.dragPosition = point;
    
    CGRect f = self.dragger.bounds;
    f.origin.x = point.x - self.dragger.bounds.size.width/2;
    f.origin.y = point.y - self.dragger.bounds.size.height/2;
    self.dragger.frame = f;
    
    CGPoint normalizedPoint = CGPointMake(self.dragPosition.x/self.bounds.size.width, self.dragPosition.y/self.bounds.size.height);
    
    [[self delegate] didPanPosition:normalizedPoint  sender:self];    
}

- (void) updateDraggerPosition:(CGPoint) point
{
    CGRect frame = self.dragger.bounds;
    frame.origin.x = point.x*self.bounds.size.width  - self.dragger.bounds.size.width/2;
    frame.origin.y = point.y*self.bounds.size.height - self.dragger.bounds.size.height/2;
    self.dragger.frame = frame;
}

- (void) handleFXDoubleTap: (UILongPressGestureRecognizer *) recognizer
{
    NSLog(@"handleFXDoubleTap - recognizer state ");
    [self.delegate didDoubleTapXY:self];
}


@end


#pragma mark --- DraggerView - Class ---


@implementation DraggerView
- (id) initWithFrame: (CGRect) frame
{
    if (self = [super initWithFrame:frame])
    {
        int dragW = 640; // 640
        
        //self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.0];
        CGRect rec = CGRectMake(0, 0, dragW*2,dragW*2);
        self.frame = rec;
        self.layer.anchorPoint = CGPointMake(0, 0);

        
        UIView *imgView=[[UIView alloc] initWithFrame:CGRectMake (0, 0, dragW*2,dragW*2)];
        _horzLine = [[UIView alloc] initWithFrame:CGRectMake     (0, dragW, dragW*2,1)];
        _vertLine = [[UIView alloc] initWithFrame:CGRectMake     (dragW, 0, 1,dragW*2)];
        _horzLine.backgroundColor = [UIColor redColor];
        _vertLine.backgroundColor = [UIColor redColor];
        _horzLine.alpha = 0.18;
        _vertLine.alpha = 0.18;
        [imgView addSubview:_horzLine];
        [imgView addSubview:_vertLine];
        
        [self addSubview:imgView];  // addSubView to UIView
    }
    return self;
}

@end


@implementation FollowerView
- (id) initWithFrame: (CGRect) frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];//[UIColor colorWithWhite:1 alpha:0.0];
        CGRect rec = CGRectMake(0, 0, SIDELENGTH, SIDELENGTH);
        self.frame = rec;
        self.layer.anchorPoint = CGPointMake(0, 0);
        
        _describeLabel = [[UILabel alloc] initWithFrame:CGRectMake(1, 0, SIDELENGTH, SIDELENGTH-1)];
        _describeLabel.text = @"X";
        _describeLabel.font = [UIFont boldSystemFontOfSize:18];
        _describeLabel.textColor = [UIColor blackColor];
        _describeLabel.textAlignment = NSTextAlignmentCenter;
        _describeLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_describeLabel];
    }
    return self;
}

-(void)drawRect:(CGRect)rect
{
    _describeLabel.text = [NSString stringWithFormat:@"%i", _followerNo];
    
    UIColor *color          = [self.circleCol colorWithAlphaComponent:1]; // 0.5
    CGRect innerRectangle   = CGRectMake (0,0,SIDELENGTH/1,SIDELENGTH/1);
    CGContextRef context    = UIGraphicsGetCurrentContext();
    [color set];
    // draw ellipse
    CGContextFillEllipseInRect(context, innerRectangle);
    UIGraphicsEndImageContext();
    
}

- (void) setDraggerPosition:(CGPoint) point withFrameSize:(CGSize) size
{
    CGRect frame = self.frame;
    frame.origin = CGPointMake( point.x * size.width  - self.bounds.size.width/2,
                                point.y * size.height - self.bounds.size.height/2);
    self.frame = frame;
}


@end


