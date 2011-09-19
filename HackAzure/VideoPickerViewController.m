//
//  VideoPickerViewController.m
//  HackAzure
//
//  Created by Marco Gasparetto on 17/09/11.
//  Copyright 2011 Superpartes. All rights reserved.
//

#import "VideoPickerViewController.h"

@implementation VideoPickerViewController

@synthesize cameraView = _cameraView;
@synthesize countdownLabel = _countdownLabel;
@synthesize nuovoViewControllerDelegate;
@synthesize moviePath;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.moviePath = nil;
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    _countdownTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(refreshCountdown:) userInfo:nil repeats:YES];
    _startDate = [[NSDate date] retain];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [_countdownTimer invalidate];
    [_countdownTimer release];
    [_startDate release];

    self.cameraView = nil;
    self.countdownLabel = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self startVideoCapture];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self stopVideoCapture];
}

- (void)refreshCountdown:(id)sender
{
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeDifference = 5.f - [currentDate timeIntervalSinceDate:_startDate];
    self.countdownLabel.text = [NSString stringWithFormat:@"%.2f", timeDifference];
    
    if (timeDifference < 0.f) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark - Video Picker

AVCaptureSession *captureSession = nil;
AVCaptureDeviceInput *input = nil;
AVCaptureMovieFileOutput *output = nil;
AVCaptureVideoPreviewLayer *previewLayer = nil;

- (void)startVideoCapture
{
    if (captureSession != nil)
        return;
    
	AVCaptureDevice *captureDevice = nil;
	NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameras) {
        if (device.position == AVCaptureDevicePositionFront) {
            captureDevice = device;
        }
    }
	if (captureDevice == nil) {
		return;
	}
    
	captureSession = [[AVCaptureSession alloc] init];
	[captureSession beginConfiguration];
	
	[captureSession setSessionPreset:AVCaptureSessionPreset640x480];
	
	input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    [captureSession addInput:input];
    
    output = [[AVCaptureMovieFileOutput alloc] init];
    [captureSession addOutput:output];
    
	previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
	previewLayer.frame = self.cameraView.bounds;
	previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	previewLayer.orientation = AVCaptureVideoOrientationPortrait;

	[captureSession commitConfiguration];
	[captureSession startRunning];

    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"MOVIE%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"m4v"]];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    [output startRecordingToOutputFileURL:fileURL recordingDelegate:self];
    self.moviePath = filePath;
    
	[self.cameraView.layer addSublayer:previewLayer];
}

- (void)stopVideoCapture
{
    if (captureSession == nil)
        return;
    
    [previewLayer removeFromSuperlayer];
    
    [captureSession stopRunning];
	[captureSession release];
    captureSession = nil;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    BOOL recordedSuccessfully = YES;
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            recordedSuccessfully = [value boolValue];
        }
    }
    
    // Continue as appropriate...
    [nuovoViewControllerDelegate dismissVideoPicker:self];
}

@end
