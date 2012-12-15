//
//  AppController.m
//  VideoDraw
//
//  Created by Демидов Александр on 06.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import "AppController.h"
#import "DrawingView.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

#define SIZE_OF_MASK 5*5

int mask[] = {1.0, 1.0, 1.0, 1.0, 1.0,
              1.0, 1.0, 1.0, 1.0, 1.0,
              1.0, 1.0, 1.0, 1.0, 1.0,
              1.0, 1.0, 1.0, 1.0, 1.0,
              1.0, 1.0, 1.0, 1.0, 1.0};

typedef struct _pixel {
    int RED, GREEN, BLUE;
} pixel;

pixel getPixelFromBGRAArray(int pixNum, unsigned char *array) {
    pixel Pixel;
    int number = 4 * pixNum;
    Pixel.BLUE = array[number];
    Pixel.GREEN = array[number + 1];
    Pixel.RED = array[number + 2];
    return Pixel;
}

BOOL getPointCoordsFromImageArray(NSPoint *coords, CVImageBufferRef imageBuffer, const short int size) {
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    unsigned width = (unsigned)CVPixelBufferGetWidth(imageBuffer);
    unsigned height = (unsigned)CVPixelBufferGetHeight(imageBuffer);
    
    if (!((width % size) == 0 && (height % size) == 0)) return NO;
    
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
//    CGContextRelease(context);
//    CGColorSpaceRelease(colorSpace);
//
//    
//    CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("newImage.jpg"), kCFURLPOSIXPathStyle, NO);
//    CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, 0);
//    CGImageDestinationAddImage(dest, quartzImage, 0);
//    CGImageDestinationFinalize(dest);
//    CFRelease(url);
//    CGImageRelease(quartzImage);
    
    
    unsigned x = 0, y = 0;
    BOOL returnValue = NO;
    float redAverage = 0.0, greenAverage = 0.0, blueAverage = 0.0, temp = 0.0, response = 0.0;
    pixel pix;
    int globalIndex = 0;
    unsigned arraySize = width*height;
    unsigned maskSize = size * size;
    
    while (globalIndex < arraySize) {
        
        for (int r = 0; r < size; r++) {
            for (int c = 0; c < size; c++) {
                pix = getPixelFromBGRAArray(globalIndex + c + r*width, baseAddress);
                redAverage += pix.RED;
                greenAverage += pix.GREEN;
                blueAverage += pix.BLUE;
            }
        }
        
        temp = (redAverage + greenAverage + blueAverage) / maskSize;
        if (temp > response) {
            coords->x = x;
            coords->y = y;
            response = temp;
            returnValue = YES;
        }
        
        redAverage = greenAverage = blueAverage = 0.0;
        
        x++;
        globalIndex += size;
        if (globalIndex % width == 0) {
            x = 0;
            y++;
            globalIndex += (size - 1)*width;
        }
    }
    
    return returnValue;
}



@implementation AppController

@synthesize videoView = _videoView;
@synthesize drawView = _drawView;

- (void)awakeFromNib
{
    [self.videoView setWantsLayer:YES];
    [self loadVideo];
}

- (void)loadVideo
{
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    if([session canSetSessionPreset:AVCaptureSessionPresetMedium])
        session.sessionPreset =  AVCaptureSessionPresetMedium;
    
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSColor *color = [[NSColor blueColor] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    CGFloat components[4];
    [color getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
    CGColorRef cgColor = CGColorCreate(colorSpace, components);
    
    [self.videoView.layer setBackgroundColor:cgColor];
    CGColorSpaceRelease (colorSpace);
    CGColorRelease (cgColor);
    
    _videoLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    _videoLayer.frame = self.videoView.layer.bounds;
    [self.videoView.layer addSublayer:_videoLayer];
    
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] error:nil];
    
    if(!videoInput) NSLog(@"Couldn't create input!");
    else {
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        [output setSampleBufferDelegate:self queue:queue];
        dispatch_release(queue);
        
        [session beginConfiguration];
        
        [session removeInput:videoInput];
        if([session canAddInput:videoInput])
            [session addInput:videoInput];
        
        if([session canAddOutput:output])
            [session addOutput:output];
        
        [session commitConfiguration];
        [session startRunning];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    NSPoint newPoint;
    if (getPointCoordsFromImageArray(&newPoint, imageBuffer, 5)) {
        NSLog(@"New point at x = %.1f y = %.1f detected", newPoint.x, newPoint.y);
        [self.drawView drawPointAtX:newPoint.x andY:newPoint.y];
    }
    else NSLog(@"No points found");
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//    exit(EXIT_FAILURE);
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    _videoLayer.frame = self.videoView.layer.bounds;
    return frameSize;
}

@end
