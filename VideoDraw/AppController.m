//
//  AppController.m
//  VideoDraw
//
//  Created by Демидов Александр on 06.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import "AppController.h"
#import "DrawingView.h"

@implementation AppController

@synthesize videoView = _videoView;
@synthesize drawView = _drawView;
@synthesize isDrawing = _isDrawing;
@synthesize preview = _preview;

#pragma mark - Lifecycle methods

- (void)awakeFromNib
{
    self.isDrawing = NO;
    [self.videoView setDelegate:self];
}

#pragma mark - Actions

- (IBAction)toggleDrawing:(NSButton *)sender
{
    if (self.isDrawing) {
        self.isDrawing = NO;
        [sender setTitle:@"Begin Drawing"];
    }
    else {
        self.isDrawing = YES;
        [sender setTitle:@"Stop Drawing"];
    }
}

- (IBAction)cleanDrawView:(NSButton *)sender
{
    if (!self.isDrawing) {
        [self.drawView clearPoints];
    }
}

#pragma mark - Delegate methods

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    self.videoView.videoLayer.frame = self.videoView.layer.bounds;
    self.videoView.rectLayer.frame = self.videoView.layer.bounds;
    return frameSize;
}

- (void)videoView:(VideoView *)view foundPointWithCoords:(NSPoint)point
{
    if (self.isDrawing) {
#warning i should transform coords here
        NSLog(@"point was found");
        [self.drawView drawPointAtX:point.x andY:point.y];
    }
}

- (void)videoView:(VideoView *)view selectedImageMask:(CGImageRef)cgImage
{
    NSImage *finalImage = [[NSImage alloc] initWithCGImage:cgImage size:self.preview.frame.size];
    [self.preview setImage:finalImage];
}

@end
