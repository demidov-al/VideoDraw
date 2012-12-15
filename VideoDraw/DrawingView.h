//
//  DrawingView.h
//  VideoDraw
//
//  Created by Александр Демидов on 09.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DrawingView : NSView

@property (readonly, nonatomic, strong) NSMutableArray *points;

- (void)drawPointAtX:(float)X andY:(float)Y;

@end
