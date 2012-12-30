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
#define GLOBAL_EPS 50

unsigned current_red_mask[] = {1.0, 1.0, 1.0, 1.0, 1.0,
							1.0, 1.0, 1.0, 1.0, 1.0,
							1.0, 1.0, 1.0, 1.0, 1.0,
							1.0, 1.0, 1.0, 1.0, 1.0,
							1.0, 1.0, 1.0, 1.0, 1.0};

unsigned current_green_mask[] = {1.0, 1.0, 1.0, 1.0, 1.0,
							  1.0, 1.0, 1.0, 1.0, 1.0,
							  1.0, 1.0, 1.0, 1.0, 1.0,
							  1.0, 1.0, 1.0, 1.0, 1.0,
							  1.0, 1.0, 1.0, 1.0, 1.0};

unsigned current_blue_mask[] = {1.0, 1.0, 1.0, 1.0, 1.0,
							 1.0, 1.0, 1.0, 1.0, 1.0,
							 1.0, 1.0, 1.0, 1.0, 1.0,
							 1.0, 1.0, 1.0, 1.0, 1.0,
							 1.0, 1.0, 1.0, 1.0, 1.0};


#pragma mark - Helpful functions

pixel getPixelFromBGRAArray(int pixNum, unsigned char *array) {
    pixel Pixel;
    int number = 4 * pixNum;
    Pixel.BLUE = (unsigned)array[number];
    Pixel.GREEN = (unsigned)array[number + 1];
    Pixel.RED = (unsigned)array[number + 2];
    return Pixel;
}

pixel getPixelFromRGBAArray(int pixNum, unsigned char *array) {
    pixel Pixel;
    int number = 4 * pixNum;
    Pixel.BLUE = (float)array[number + 2];
    Pixel.GREEN = (float)array[number + 1];
    Pixel.RED = (float)array[number];
    return Pixel;
}

BOOL compareMasks(unsigned *firstMask, unsigned *secondMask, int eps, int size) {
	for (int i = 0; i < size; i++) {
		if (abs((int)firstMask[i] - (int)secondMask[i]) > eps) {
			return NO;
		}
	}
	return YES;
}

BOOL getPointCoordsFromImageArray(NSPoint *coords, uint8_t *baseAddress, unsigned width, unsigned height, const short int size) {
    if (!((width % size) == 0 && (height % size) == 0)) return NO;
    
    unsigned x = 0, y = 0;
    BOOL returnValue = NO;
    int globalIndex = 0;
    unsigned arraySize = width*height;
    unsigned maskSize = size * size;
	
	unsigned redMask[SIZE_OF_MASK];
	unsigned greenMask[SIZE_OF_MASK];
	unsigned blueMask[SIZE_OF_MASK];
//	pixel maxPix;
    
    while (globalIndex < arraySize) {
//		maxPix.RED = maxPix.GREEN = maxPix.BLUE = 0.0;
//        for (int r = 0; r < size; r++) {
//            for (int c = 0; c < size; c++) {
//                pixel temp_pixel = getPixelFromBGRAArray(globalIndex + c + r*width, baseAddress);
//				if (temp_pixel.RED > maxPix.RED) maxPix.RED = temp_pixel.RED;
//				if (temp_pixel.GREEN > maxPix.GREEN) maxPix.GREEN = temp_pixel.GREEN;
//				if (temp_pixel.BLUE > maxPix.BLUE) maxPix.BLUE = temp_pixel.BLUE;
//            }
//        }
		
		for (int r = 0; r < size; r++) {
            for (int c = 0; c < size; c++) {
                pixel temp_pixel = getPixelFromBGRAArray(globalIndex + c + r*width, baseAddress);
				redMask[r*size + c] = temp_pixel.RED;// / maxPix.RED;
				greenMask[r*size + c] = temp_pixel.GREEN;// / maxPix.GREEN;
				blueMask[r*size + c] = temp_pixel.BLUE;// / maxPix.BLUE;
            }
        }
		
		
        if (compareMasks(redMask, current_red_mask, GLOBAL_EPS, maskSize) &&
			compareMasks(greenMask, current_green_mask, GLOBAL_EPS, maskSize) &&
			compareMasks(blueMask, current_blue_mask, GLOBAL_EPS, maskSize)) {
            coords->x = x;
            coords->y = y;
            returnValue = YES;
			break;
        }
        
        x++;
        globalIndex += size;
//		globalIndex += 1;
        if (globalIndex % width == 0) {
            x = 0;
            y++;
            globalIndex += (size - 1)*width;
//			globalIndex += width;
        }
    }
    
    return returnValue;
}


@interface AppController ()

- (CGImageRef)analyzeImageForMask:(CGImageRef)maskImage;

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

- (CGImageRef)analyzeImageForMask:(CGImageRef)maskImage
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char *)calloc(SIZE_OF_MASK * 4, sizeof(unsigned char));
    CGContextRef context = CGBitmapContextCreate(rawData, SIZE_OF_MASK/5, SIZE_OF_MASK/5, 8, SIZE_OF_MASK/5 * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, SIZE_OF_MASK/5, SIZE_OF_MASK/5), maskImage);
	CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
//    pixel Pix;
//    Pix.RED = Pix.GREEN = Pix.BLUE = 0.0;
//    for (int i = 0; i < SIZE_OF_MASK; i++) {
//        pixel temp_pixel = getPixelFromRGBAArray(i, rawData);
//        
//        if (temp_pixel.RED > Pix.RED) Pix.RED = temp_pixel.RED;
//        if (temp_pixel.GREEN > Pix.GREEN) Pix.GREEN = temp_pixel.GREEN;
//        if (temp_pixel.BLUE > Pix.BLUE) Pix.BLUE = temp_pixel.BLUE;
//    }
    
    for (int i = 0; i < SIZE_OF_MASK; i++) {
        pixel temp_pixel = getPixelFromRGBAArray(i, rawData);
        current_red_mask[i] = temp_pixel.RED;// / Pix.RED;
        current_green_mask[i] = temp_pixel.GREEN;// / Pix.GREEN;
        current_blue_mask[i] = temp_pixel.BLUE;// / Pix.BLUE;
    }
	
    free(rawData);
	return quartzImage;
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
    
	CGImageRef resultImage = [self analyzeImageForMask:smallImage];
    NSImage *finalImage = [[NSImage alloc] initWithCGImage:resultImage size:self.preview.frame.size];
    [self.preview setImage:finalImage];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(quartzImage);
    CGImageRelease(smallImage);
	CGImageRelease(resultImage);
}

@end
