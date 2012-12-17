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
#define EPS 50

float red_mask[] = {1.0, 1.0, 1.0, 1.0, 1.0,
                    1.0, 1.0, 1.0, 1.0, 1.0,
                    1.0, 1.0, 1.0, 1.0, 1.0,
                    1.0, 1.0, 1.0, 1.0, 1.0,
                    1.0, 1.0, 1.0, 1.0, 1.0};

float green_mask[] = {1.0, 1.0, 1.0, 1.0, 1.0,
                      1.0, 1.0, 1.0, 1.0, 1.0,
                      1.0, 1.0, 1.0, 1.0, 1.0,
                      1.0, 1.0, 1.0, 1.0, 1.0,
                      1.0, 1.0, 1.0, 1.0, 1.0};

float blue_mask[] = {1.0, 1.0, 1.0, 1.0, 1.0,
                     1.0, 1.0, 1.0, 1.0, 1.0,
                     1.0, 1.0, 1.0, 1.0, 1.0,
                     1.0, 1.0, 1.0, 1.0, 1.0,
                     1.0, 1.0, 1.0, 1.0, 1.0};

float originalRedChannelEqv = 0.0, originalGreenChannelEqv = 0.0, originalBlueChannelEqv = 0.0;

#pragma mark - Helpful functions

pixel getPixelFromBGRAArray(int pixNum, unsigned char *array) {
    pixel Pixel;
    int number = 4 * pixNum;
    Pixel.BLUE = (float)array[number];
    Pixel.GREEN = (float)array[number + 1];
    Pixel.RED = (float)array[number + 2];
    return Pixel;
}

pixel getPixelFromRGBAArray(int pixNum, unsigned char *array) {
    pixel Pixel;
    int number = 4 * pixNum;
    Pixel.BLUE = (float)array[number+2];
    Pixel.GREEN = (float)array[number + 1];
    Pixel.RED = (float)array[number];
    return Pixel;
}

BOOL getPointCoordsFromImageArray(NSPoint *coords, uint8_t *baseAddress, unsigned width, unsigned height, const short int size) {
    if (!((width % size) == 0 && (height % size) == 0)) return NO;
    
    unsigned x = 0, y = 0;
    BOOL returnValue = NO;
    float redChannelEqv = 0.0, greenChannelEqv = 0.0, blueChannelEqv = 0.0, temp = 0.0, response = 0.0;
    pixel pix;
    int globalIndex = 0;
    unsigned arraySize = width*height;
    unsigned maskSize = size * size;
    
    while (globalIndex < arraySize) {
        
        for (int r = 0; r < size; r++) {
            for (int c = 0; c < size; c++) {
                pix = getPixelFromBGRAArray(globalIndex + c + r*width, baseAddress);
                redChannelEqv += pix.RED*red_mask[r*size+c];
                blueChannelEqv += pix.BLUE*blue_mask[r*size+c];
                greenChannelEqv += pix.GREEN*green_mask[r*size+c];
#warning there is mistake here
            }
        }
        
        redChannelEqv /= maskSize;
        blueChannelEqv /= maskSize;
        greenChannelEqv /= maskSize;
        NSLog(@"%f %f %f", fabsf(redChannelEqv - originalRedChannelEqv), fabsf(greenChannelEqv - originalGreenChannelEqv), fabsf(blueChannelEqv - originalBlueChannelEqv));
        if (fabsf(redChannelEqv - originalRedChannelEqv) < EPS && fabsf(greenChannelEqv - originalGreenChannelEqv) < EPS && fabsf(blueChannelEqv - originalBlueChannelEqv) < EPS) {
            coords->x = x;
            coords->y = y;
            response = temp;
            returnValue = YES;
        }
        
        redChannelEqv = greenChannelEqv = blueChannelEqv = 0.0;
        
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
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char *)calloc(SIZE_OF_MASK * 4, sizeof(unsigned char));
    CGContextRef context = CGBitmapContextCreate(rawData, SIZE_OF_MASK/5, SIZE_OF_MASK/5, 8, SIZE_OF_MASK/5 * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, SIZE_OF_MASK/5, SIZE_OF_MASK/5), maskImage);
    CGContextRelease(context);
    
    pixel Pix;
    Pix.RED = Pix.GREEN = Pix.BLUE = 0.0;
    for (int i = 0; i < SIZE_OF_MASK; i++) {
        pixel temp_pixel = getPixelFromRGBAArray(i, rawData);
        
        if (temp_pixel.RED > Pix.RED) Pix.RED = temp_pixel.RED;
        if (temp_pixel.GREEN > Pix.GREEN) Pix.GREEN = temp_pixel.GREEN;
        if (temp_pixel.BLUE > Pix.BLUE) Pix.BLUE = temp_pixel.BLUE;
    }
    
    for (int i = 0; i < SIZE_OF_MASK; i++) {
        pixel temp_pixel = getPixelFromRGBAArray(i, rawData);
        red_mask[i] = temp_pixel.RED / Pix.RED;
        green_mask[i] = temp_pixel.GREEN / Pix.GREEN;
        blue_mask[i] = temp_pixel.BLUE / Pix.BLUE;
        
//        if (red_mask[i] > 1.0 || green_mask[i] > 1.0 || blue_mask[i] > 1.0) {
//            NSLog(@"temp: %.1f %.1f %.1f Pix: %.1f %.1f %.1f", temp_pixel.RED, temp_pixel.GREEN, temp_pixel.BLUE, Pix.RED, Pix.GREEN, Pix.BLUE);
//            NSLog(@"r %.1f g %.1f b %.1f", red_mask[i], green_mask[i], blue_mask[i]);
//        }
        
        originalBlueChannelEqv += Pix.BLUE;
        originalRedChannelEqv += Pix.RED;
        originalGreenChannelEqv += Pix.GREEN;
    }
    originalBlueChannelEqv /= SIZE_OF_MASK;
    originalGreenChannelEqv /= SIZE_OF_MASK;
    originalRedChannelEqv /= SIZE_OF_MASK;
//    NSLog(@"Original Eqvs: r = %f g = %f b = %f", originalRedChannelEqv, originalGreenChannelEqv, originalBlueChannelEqv);
    
    free(rawData);
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
    if (getPointCoordsFromImageArray(&newPoint, self.baseAddress, width, height, SIZE_OF_MASK/5)) {
        NSLog(@"Found point!");
        [self.drawView drawPointAtX:newPoint.x andY:newPoint.y];
    }
//    else NSLog(@"No points found");
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
