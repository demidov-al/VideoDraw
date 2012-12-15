//
//  AppDelegate.m
//  VideoDraw
//
//  Created by Демидов Александр on 06.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSSize windowSize = NSMakeSize(720, 550);
    [self.window setAspectRatio:windowSize];
//    [self.window setContentAspectRatio:windowSize];
}

@end
