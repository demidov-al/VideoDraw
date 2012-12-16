//
//  VideoView.m
//  VideoDraw
//
//  Created by Александр Демидов on 16.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import "VideoView.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

@implementation VideoView

@synthesize delegate = _delegate;
@synthesize videoLayer = _videoLayer;
@synthesize rectLayer = _rectLayer;

#pragma mark - Lifecycle methods

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    
    return self;
}

#pragma mark - Public methods

- (BOOL)prepareForVideoWithSession:(AVCaptureSession *)session
{
    [self setWantsLayer:YES];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSColor *color = [[NSColor blueColor] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    CGFloat components[4];
    [color getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
    CGColorRef cgColor = CGColorCreate(colorSpace, components);
    
    [self.layer setBackgroundColor:cgColor];
    CGColorSpaceRelease(colorSpace);
    CGColorRelease(cgColor);
    
    _videoLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [_videoLayer setFrame:self.layer.bounds];
    [self.layer addSublayer:_videoLayer];
    
    _rectLayer = [CALayer layer];
    [self.rectLayer setDelegate:self];
    [self.rectLayer setFrame:self.layer.bounds];
    [self.layer addSublayer:self.rectLayer];
    
    if (self.rectLayer == nil || _videoLayer == nil) return NO;
    else return YES;
}

#pragma mark - Delegate methods

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if ([layer isEqual:self.rectLayer]) {
        if (shouldClear) return;
        else {
            CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.5);
            CGContextFillRect(ctx, CGRectMake(startPoint.x, startPoint.y, currentPoint.x - startPoint.x, currentPoint.y - startPoint.y));
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    startPoint = theEvent.locationInWindow;
    startPoint.x -= self.frame.origin.x;
    startPoint.y -= self.frame.origin.y;
    shouldClear = NO;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    currentPoint = theEvent.locationInWindow;
    currentPoint.x -= self.frame.origin.x;
    currentPoint.y -= self.frame.origin.y;
    [self.rectLayer setNeedsDisplay];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    shouldClear = YES;
    [self.rectLayer setNeedsDisplay];
    
    if ([self.delegate respondsToSelector:@selector(doSnapshotWithRect:)]) {
        NSRect destinationRect = NSMakeRect(startPoint.x, startPoint.y, currentPoint.x - startPoint.x, currentPoint.y - startPoint.y);
        [self.delegate doSnapshotWithRect:destinationRect];
        NSLog(@"message sent");
    }
}

@end
