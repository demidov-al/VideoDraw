//
//  AppController.h
//  VideoDraw
//
//  Created by Демидов Александр on 06.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@class DrawingView;

@interface AppController : NSObject <NSWindowDelegate, AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureVideoPreviewLayer *_videoLayer;
}

@property (weak) IBOutlet NSView *videoView;
@property (weak) IBOutlet DrawingView *drawView;

- (void)loadVideo;

@end
