//
//  VideoView.h
//  VideoDraw
//
//  Created by Александр Демидов on 16.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AVCaptureVideoPreviewLayer;
@class AVCaptureSession;

@protocol VideoViewDelegate;

@interface VideoView : NSView {
    NSPoint startPoint;
    NSPoint currentPoint;
    BOOL shouldClear;
}

@property (nonatomic) id <VideoViewDelegate> delegate;
@property (strong, readonly) AVCaptureVideoPreviewLayer *videoLayer;
@property (strong, readonly) CALayer *rectLayer;

- (BOOL)prepareForVideoWithSession:(AVCaptureSession *)session;

@end


@protocol VideoViewDelegate <NSObject>

- (void)doSnapshotWithRect:(NSRect)snapshotRect;

@end