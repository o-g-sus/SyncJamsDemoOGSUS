//
//  OGKnob.h
//  Knoboli2
//
//  Created by Oliver Greschke on 04.12.12.
//  Copyright (c) 2012 Oliver Greschke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DraggerView : UIView
@property (nonatomic, strong) UIView *horzLine;
@property (nonatomic, strong) UIView *vertLine;
@end


@interface FollowerView : UIView
@property (nonatomic) int  followerNo;
@property (nonatomic, strong) UIColor *circleCol;
@property (nonatomic, strong) UILabel *describeLabel;
- (void) setDraggerPosition:(CGPoint) point withFrameSize:(CGSize) rect;
@end


@protocol XYDragControlDelegate <NSObject>
@required
- (void) didPanPosition: (CGPoint)point sender:(id)sender;
@optional
- (void) didPanEnd: (id)sender;
- (void) didDoubleTapXY: (id) sender;
@end


@interface XYDragControl : UIView

@property (nonatomic, strong) DraggerView *dragger;

@property (nonatomic) CGPoint dragPosition;
@property (nonatomic) UILabel *horitontalLabel;
@property (nonatomic) UILabel *vertikalLabel;

@property (weak, nonatomic) id <XYDragControlDelegate> delegate;

- (void) setupXYView;
- (void) setDraggerPosition:(CGPoint) point;
- (void) setDraggerPositionNormalized:(CGPoint) point;
- (void) updateDraggerPosition:(CGPoint) point;

//- (void) updateView;

@end