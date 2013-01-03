//
//  AppController.h
//  VideoDraw
//
//  Created by Демидов Александр on 06.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoView.h"

@class DrawingView;

@interface AppController : NSObject <NSWindowDelegate, VideoViewDelegate>

@property (weak) IBOutlet VideoView *videoView;
@property (weak) IBOutlet DrawingView *drawView;
@property (weak) IBOutlet NSImageView *preview;
@property BOOL isDrawing;

- (IBAction)toggleDrawing:(NSButton *)sender;
- (IBAction)cleanDrawView:(NSButton *)sender;

@end
