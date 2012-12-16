//
//  AppController.h
//  VideoDraw
//
//  Created by Демидов Александр on 06.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoView.h"

typedef struct _pixel {
    float RED, GREEN, BLUE;
} pixel;

@class DrawingView;
@class VideoView;

@interface AppController : NSObject <NSWindowDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, VideoViewDelegate> {
    unsigned width, height, bytesPerRow;
}

@property (weak) IBOutlet VideoView *videoView;
@property (weak) IBOutlet DrawingView *drawView;
@property (weak) IBOutlet NSImageView *preview;
@property uint8_t *baseAddress;
@property BOOL isDrawing;

- (void)loadVideo;
- (IBAction)toggleDrawing:(NSButton *)sender;
- (IBAction)cleanDrawView:(NSButton *)sender;
- (void)doSnapshotWithRect:(NSRect)snapshotRect;

@end
