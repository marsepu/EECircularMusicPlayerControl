//
//  DACircularProgressView.m
//  DACircularProgress
//
//  Created by Daniel Amitay on 2/6/12.
//  Copyright (c) 2012 Daniel Amitay. All rights reserved.
//

#import "DACircularProgressView.h"

@implementation DACircularProgressLayer

@synthesize trackTintColor = _trackTintColor;
@synthesize progressTintColor = _progressTintColor;
@synthesize highlightedTrackTintColor = _highlightedTrackTintColor;
@synthesize highlightedProgressTintColor = _highlightedProgressTintColor;
@synthesize roundedCorners = _roundedCorners;
@synthesize thicknessRatio = _thicknessRatio;
@synthesize progress = _progress;
@synthesize enabled = _enabled;
@synthesize highlighted = _highlighted;

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    return [key isEqualToString:@"progress"] ? YES : [super needsDisplayForKey:key];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.enabled = YES;
    }
    return self;
}

- (id)initWithLayer:(DACircularProgressLayer *)layer
{
    self = [super initWithLayer:layer];
    if (self)
    {
        self.trackTintColor = layer.trackTintColor;
        self.progressTintColor = layer.progressTintColor;
        self.highlightedTrackTintColor = layer.highlightedTrackTintColor;
        self.highlightedProgressTintColor = layer.highlightedTrackTintColor;
        self.roundedCorners = layer.roundedCorners;
        self.thicknessRatio = layer.thicknessRatio;
        self.progress = layer.progress;
        self.enabled = layer.enabled;
        self.highlighted = layer.highlighted;
    }
    return self;
}

- (void)drawInContext:(CGContextRef)context
{
    CGRect rect = self.bounds;
    CGPoint centerPoint = CGPointMake(rect.size.height / 2, rect.size.width / 2);
    CGFloat radius = MIN(rect.size.height, rect.size.width) / 2;
    
    CGFloat progress = MIN(self.progress, 1.f - FLT_EPSILON);
    CGFloat radians = (progress * 2 * M_PI) - M_PI_2;
    
    UIColor *trackTintColor, *progressTintColor;
    if (self.enabled) {
        trackTintColor = self.highlighted ? self.highlightedTrackTintColor : self.trackTintColor;
        progressTintColor = self.highlighted ? self.highlightedProgressTintColor : self.progressTintColor;
    }
    else {
        CGFloat factor = 0.75f;
        trackTintColor = [self.trackTintColor colorWithAlphaComponent:factor];
        progressTintColor = [self.progressTintColor colorWithAlphaComponent:factor];
    }
    
    CGContextSetFillColorWithColor(context, trackTintColor.CGColor);
    CGMutablePathRef trackPath = CGPathCreateMutable();
    CGPathMoveToPoint(trackPath, NULL, centerPoint.x, centerPoint.y);
    CGPathAddArc(trackPath, NULL, centerPoint.x, centerPoint.y, radius, 3 * M_PI_2, -M_PI_2, NO);
    CGPathCloseSubpath(trackPath);
    CGContextAddPath(context, trackPath);
    CGContextFillPath(context);
    CGPathRelease(trackPath);
    
    if (progress > 0.f)
    {
        CGContextSetFillColorWithColor(context, progressTintColor.CGColor);
        CGMutablePathRef progressPath = CGPathCreateMutable();
        CGPathMoveToPoint(progressPath, NULL, centerPoint.x, centerPoint.y);
        CGPathAddArc(progressPath, NULL, centerPoint.x, centerPoint.y, radius, 3 * M_PI_2, radians, NO);
        CGPathCloseSubpath(progressPath);
        CGContextAddPath(context, progressPath);
        CGContextFillPath(context);
        CGPathRelease(progressPath);
    }
    
    if (progress > 0.f && self.roundedCorners)
    {
        CGFloat pathWidth = radius * self.thicknessRatio;
        CGFloat xOffset = radius * (1.f + ((1 - (self.thicknessRatio / 2.f)) * cosf(radians)));
        CGFloat yOffset = radius * (1.f + ((1 - (self.thicknessRatio / 2.f)) * sinf(radians)));
        CGPoint endPoint = CGPointMake(xOffset, yOffset);
        
        CGContextAddEllipseInRect(context, CGRectMake(centerPoint.x - pathWidth / 2, 0, pathWidth, pathWidth));
        CGContextFillPath(context);
        
        CGContextAddEllipseInRect(context, CGRectMake(endPoint.x - pathWidth / 2, endPoint.y - pathWidth / 2, pathWidth, pathWidth));
        CGContextFillPath(context);
    }
    
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGFloat innerRadius = radius * (1.f - self.thicknessRatio);
    CGPoint newCenterPoint = CGPointMake(centerPoint.x - innerRadius, centerPoint.y - innerRadius);
    CGContextAddEllipseInRect(context, CGRectMake(newCenterPoint.x, newCenterPoint.y, innerRadius * 2, innerRadius * 2));
    CGContextFillPath(context);
}

@end

@implementation DACircularProgressView

+ (void) initialize
{
    if (self != [DACircularProgressView class])
        return;
    
    id appearance = [self appearance];
    [appearance setTrackTintColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3f]];
    [appearance setProgressTintColor:[UIColor whiteColor]];
    [appearance setThicknessRatio:0.3f];
    [appearance setRoundedCorners:NO];
}

+ (Class)layerClass
{
    return [DACircularProgressLayer class];
}

- (DACircularProgressLayer *)circularProgressLayer
{
    return (DACircularProgressLayer *)self.layer;
}

- (id)init
{
    return [self initWithFrame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)didMoveToWindow
{
    self.circularProgressLayer.contentsScale = [UIScreen mainScreen].scale;
}

#pragma mark - Progress

-(CGFloat)progress
{
    return self.circularProgressLayer.progress;
}

- (void)setProgress:(CGFloat)progress
{
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated
{
    CGFloat pinnedProgress = MIN(MAX(progress, 0.f), 1.f);
    if (animated)
    {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"progress"];
        animation.duration = fabsf(self.progress - pinnedProgress); // Same duration as UIProgressView animation
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.fromValue = [NSNumber numberWithFloat:self.progress];
        animation.toValue = [NSNumber numberWithFloat:pinnedProgress];
        [self.circularProgressLayer addAnimation:animation forKey:@"progress"];
    }
    else
    {
        [self.circularProgressLayer setNeedsDisplay];
    }
    self.circularProgressLayer.progress = pinnedProgress;
}

#pragma mark - UIAppearance methods

- (UIColor *)trackTintColor
{
    return self.circularProgressLayer.trackTintColor;
}

- (void)setTrackTintColor:(UIColor *)trackTintColor
{
    self.circularProgressLayer.trackTintColor = trackTintColor;
    [self.circularProgressLayer setNeedsDisplay];
}

- (UIColor *)progressTintColor
{
    return self.circularProgressLayer.progressTintColor;
}

- (void)setProgressTintColor:(UIColor *)progressTintColor
{
    self.circularProgressLayer.progressTintColor = progressTintColor;
    [self.circularProgressLayer setNeedsDisplay];
}

- (UIColor *)highlightedTrackTintColor
{
    return self.circularProgressLayer.highlightedTrackTintColor;
}

- (void)setHighlightedTrackTintColor:(UIColor *)highlightedTrackTintColor
{
    self.circularProgressLayer.highlightedTrackTintColor = highlightedTrackTintColor;
    [self.circularProgressLayer setNeedsDisplay];
}

- (UIColor *)highlightedProgressTintColor
{
    return self.circularProgressLayer.highlightedProgressTintColor;
}

- (void)setHighlightedProgressTintColor:(UIColor *)highlightedProgressTintColor
{
    self.circularProgressLayer.highlightedProgressTintColor = highlightedProgressTintColor;
    [self.circularProgressLayer setNeedsDisplay];
}

- (NSInteger)roundedCorners
{
    return self.roundedCorners;
}

-(void)setRoundedCorners:(NSInteger)roundedCorners
{
    self.circularProgressLayer.roundedCorners = roundedCorners;
    [self.circularProgressLayer setNeedsDisplay];
}

-(CGFloat)thicknessRatio
{
    return self.circularProgressLayer.thicknessRatio;
}

- (void)setThicknessRatio:(CGFloat)thicknessRatio
{
    self.circularProgressLayer.thicknessRatio = MIN(MAX(thicknessRatio, 0.f), 1.f);
    [self.circularProgressLayer setNeedsDisplay];
}

@end
