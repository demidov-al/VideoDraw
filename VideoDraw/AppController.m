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

#pragma mark - Helpful functions

pixel getPixelFromBGRAArray(int pixNum, unsigned char *array) {
    pixel Pixel;
    int number = 4 * pixNum;
    Pixel.BLUE = array[number];
    Pixel.GREEN = array[number + 1];
    Pixel.RED = array[number + 2];
    return Pixel;
}

BOOL getPointCoordsFromImageArray(NSPoint *coords, uint8_t *baseAddress, unsigned width, unsigned height, const short int size) {
    if (!((width % size) == 0 && (height % size) == 0)) return NO;
    
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


@interface AppController ()

- (void)analyzeImageForMask:(CGImageRef)maskImage;

@end

@implementation AppController

@synthesize videoView = _videoView;
@synthesize drawView = _drawView;
@synthesize isDrawing = _isDrawing;
@synthesize preview = _preview;
@synthesize baseAddress = _baseAddress;

#pragma mark - Lidecycle methods

- (void)awakeFromNib
{
    self.isDrawing = NO;
    [self loadVideo];
}

#pragma mark - Public methods

- (void)loadVideo
{
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    if([session canSetSessionPreset:AVCaptureSessionPresetMedium])
        session.sessionPreset =  AVCaptureSessionPresetMedium;
    
    [self.videoView prepareForVideoWithSession:session];
    [self.videoView setDelegate:self];
    
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
        width = 1280;
        height = 720;
        bytesPerRow = 5120;
        [session startRunning];
    }
}

#pragma mark - Private methods

- (void)analyzeImageForMask:(CGImageRef)maskImage
{
    
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

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    self.baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    if (!self.isDrawing) return;
    NSPoint newPoint;
    if (getPointCoordsFromImageArray(&newPoint, self.baseAddress, width, height, 5)) {
        [self.drawView drawPointAtX:newPoint.x andY:newPoint.y];
    }
    else NSLog(@"No points found");
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    self.videoView.videoLayer.frame = self.videoView.layer.bounds;
    self.videoView.rectLayer.frame = self.videoView.layer.bounds;
    return frameSize;
}

- (void)doSnapshotWithRect:(NSRect)snapshotRect
{
    float widthRelation = width / self.videoView.videoLayer.frame.size.width;
    float heightRelation = height / self.videoView.videoLayer.frame.size.height;
    snapshotRect.origin.x *= widthRelation;
    snapshotRect.origin.y *= heightRelation;
    snapshotRect.origin.y = height - snapshotRect.origin.y;
    snapshotRect.size.width *= widthRelation;
    snapshotRect.size.height *= -heightRelation;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(self.baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CGImageRef smallImage = CGImageCreateWithImageInRect(quartzImage, snapshotRect);
    
    NSImage *finalImage = [[NSImage alloc] initWithCGImage:smallImage size:self.preview.frame.size];
    [self.preview setImage:finalImage];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(quartzImage);
    
    [self analyzeImageForMask:smallImage];
    CGImageRelease(smallImage);
}

@end
