//
//  DrawingView.m
//  VideoDraw
//
//  Created by Александр Демидов on 09.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import "DrawingView.h"

#define RAD 2.5

@implementation DrawingView

@synthesize points = _points;

#pragma mark - Lifecycle methods

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _points = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc
{
    _points = nil;
}

#pragma mark - Public methods

- (void)drawPointAtX:(float)X andY:(float)Y
{
    NSPoint point = NSMakePoint(X, Y);
    [self.points addObject:[NSValue valueWithPoint:point]];
    [self setNeedsDisplay:YES];
}

- (void)clearPoints
{
    _points = [NSMutableArray new];
    [self setNeedsDisplay:YES];
}

#pragma mark - Delegate methods

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] set];
    NSRectFill(self.bounds);
    
    [[NSColor blackColor] set];
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    for (NSValue *pointValue in self.points) {
        NSPoint point = [pointValue pointValue];
        CGContextFillEllipseInRect(ctx, CGRectMake(point.x - RAD, point.y + RAD, 2*RAD, 2*RAD));
    }
}

@end
