//
//  VideoView.m
//  VideoDraw
//
//  Created by Александр Демидов on 16.12.12.
//  Copyright (c) 2012 Демидов Александр. All rights reserved.
//

#import "VideoView.h"
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>

#define SIZE_OF_MASK 5*5
#define GLOBAL_EPS 20

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

pixel getPixelFromBGRAArray(int pixNum, unsigned char *array) {
    pixel Pixel;
    int number = 4 * pixNum;
    Pixel.BLUE = (unsigned int)array[number];
    Pixel.GREEN = (unsigned int)array[number + 1];
    Pixel.RED = (unsigned int)array[number + 2];
    return Pixel;
}

pixel getPixelFromRGBAArray(int pixNum, unsigned char *array) {
    pixel Pixel;
    int number = 4 * pixNum;
    Pixel.BLUE = (unsigned int)array[number+2];
    Pixel.GREEN = (unsigned int)array[number + 1];
    Pixel.RED = (unsigned int)array[number];
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

@interface VideoView ()

- (BOOL)prepareForVideoWithSession:(AVCaptureSession *)session;
- (void)doSnapshotWithRect:(NSRect)snapshotRect;
- (CGImageRef)analyzeImageForMask:(CGImageRef)maskImage;

@end

@implementation VideoView

@synthesize delegate = _delegate;
@synthesize videoLayer = _videoLayer;
@synthesize rectLayer = _rectLayer;
@synthesize session = _session;

#pragma mark - Lifecycle methods

- (void)awakeFromNib
{
    videoWidth = 1280;
    videoHeight = 720;
    videoBytesPerRow = 5120;
    _session = [[AVCaptureSession alloc] init];
    
    if([_session canSetSessionPreset:AVCaptureSessionPresetMedium])
        _session.sessionPreset =  AVCaptureSessionPresetMedium;
    
    if (![self prepareForVideoWithSession:_session]) exit(EXIT_FAILURE);
    
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] error:nil];
    
    if(!videoInput) NSLog(@"Couldn't create input!");
    else {
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        [output setSampleBufferDelegate:self queue:queue];
        dispatch_release(queue);
        
        [_session beginConfiguration];
        
        [_session removeInput:videoInput];
        if([_session canAddInput:videoInput])
            [_session addInput:videoInput];
        
        if([_session canAddOutput:output])
            [_session addOutput:output];
        
        [_session commitConfiguration];
        [_session startRunning];
    }
}

- (void)dealloc
{
    _session = nil;
    _videoLayer = nil;
    _rectLayer = nil;
    _session = nil;
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
        current_red_mask[i] = temp_pixel.RED;
        current_green_mask[i] = temp_pixel.GREEN;
        current_blue_mask[i] = temp_pixel.BLUE;
    }
	
    free(rawData);
	return quartzImage;
}

- (void)doSnapshotWithRect:(NSRect)snapshotRect
{
    float widthRelation = videoWidth / self.videoLayer.frame.size.width;
    float heightRelation = videoHeight / self.videoLayer.frame.size.height;
    snapshotRect.origin.x *= widthRelation;
    snapshotRect.origin.y *= heightRelation;
    snapshotRect.origin.y = videoHeight - snapshotRect.origin.y;
//    snapshotRect.size.width *= widthRelation;
//    snapshotRect.size.height *= -heightRelation;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(self.baseAddress, videoWidth, videoHeight, 8, videoBytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CGImageRef smallImage = CGImageCreateWithImageInRect(quartzImage, snapshotRect);
    
	CGImageRef resultImage = [self analyzeImageForMask:smallImage];
    [self.delegate videoView:self selectedImageMask:resultImage];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(quartzImage);
    CGImageRelease(smallImage);
	CGImageRelease(resultImage);
}

- (BOOL)prepareForVideoWithSession:(AVCaptureSession *)session
{
    [self setWantsLayer:YES];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSColor *color = [[NSColor blueColor] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    CGFloat components[4];
    [color getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
    CGColorRef cgColor = CGColorCreate(colorSpace, components);
    
    [self.layer setBackgroundColor:cgColor];
    CGColorSpaceRelease(colorSpace);
    CGColorRelease(cgColor);
    
    _videoLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [_videoLayer setFrame:self.layer.bounds];
    [self.layer addSublayer:_videoLayer];
    
    _rectLayer = [CALayer layer];
    [self.rectLayer setDelegate:self];
    [self.rectLayer setFrame:self.layer.bounds];
    [self.layer addSublayer:self.rectLayer];
    
    if (self.rectLayer == nil || _videoLayer == nil) return NO;
    else return YES;
}

#pragma mark - Delegate methods
#pragma mark Video events

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    self.baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    NSPoint newPoint;
    if (getPointCoordsFromImageArray(&newPoint, self.baseAddress, videoWidth, videoHeight, SIZE_OF_MASK/5)) {
        [self.delegate videoView:self foundPointWithCoords:newPoint];
    }
}

#pragma mark Layer drawing events

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if ([layer isEqual:self.rectLayer]) {
        if (shouldClear) return;
        else {
            CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.5);
            float pseudoHeight = ((currentPoint.y - startPoint.y) > 0) ? (currentPoint.x - startPoint.x) : -(currentPoint.x - startPoint.x);
            pseudoHeight = (currentPoint.x - startPoint.x > 0) ? pseudoHeight : -pseudoHeight;
            CGContextFillRect(ctx, CGRectMake(startPoint.x, startPoint.y, currentPoint.x - startPoint.x, pseudoHeight));
        }
    }
}

#pragma mark Mouse events

- (void)mouseDown:(NSEvent *)theEvent
{
    startPoint = theEvent.locationInWindow;
    startPoint.x -= self.frame.origin.x;
    startPoint.y -= self.frame.origin.y;
    shouldClear = NO;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    currentPoint = theEvent.locationInWindow;
    currentPoint.x -= self.frame.origin.x;
    currentPoint.y -= self.frame.origin.y;
    [self.rectLayer setNeedsDisplay];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    shouldClear = YES;
    [self.rectLayer setNeedsDisplay];
    
//    float pseudoHeight = ((currentPoint.y - startPoint.y) > 0) ? (currentPoint.x - startPoint.x) : -(currentPoint.x - startPoint.x);
//    pseudoHeight = (currentPoint.x - startPoint.x > 0) ? pseudoHeight : -pseudoHeight;
//    NSRect destinationRect = NSMakeRect(startPoint.x, startPoint.y, currentPoint.x - startPoint.x, pseudoHeight);
    NSPoint eventPoint = theEvent.locationInWindow;
    eventPoint.x -= self.frame.origin.x;
    eventPoint.y -= self.frame.origin.y;
    NSRect destinationRect = NSMakeRect(eventPoint.x - 2.5, eventPoint.y - 2.5, 5.0, 5.0);
		
    [self doSnapshotWithRect:destinationRect];
}

@end
