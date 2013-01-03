//
//  VideoView.h
//  VideoDraw
//
//  Created by Александр Демидов on 16.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

typedef struct _pixel {
    unsigned RED, GREEN, BLUE;
} pixel;

@protocol VideoViewDelegate;

@interface VideoView : NSView <AVCaptureVideoDataOutputSampleBufferDelegate> {
    NSPoint startPoint;
    NSPoint currentPoint;
    BOOL shouldClear;
    
    unsigned videoWidth, videoHeight, videoBytesPerRow;
}

@property id <VideoViewDelegate> delegate;
@property (strong, readonly) AVCaptureVideoPreviewLayer *videoLayer;
@property (strong, readonly) CALayer *rectLayer;
@property (strong, readonly) AVCaptureSession *session;
@property uint8_t *baseAddress;

@end


@protocol VideoViewDelegate <NSObject>

@required
- (void)videoView:(VideoView *)view foundPointWithCoords:(NSPoint)point;

@optional
- (void)videoView:(VideoView *)view selectedImageMask:(CGImageRef)cgImage;

@end