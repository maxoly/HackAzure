//
//  VideoPickerViewController.h
//  HackAzure
//
//  Created by Marco Gasparetto on 17/09/11.
//  Copyright 2011 Superpartes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NuovoViewController.h"

@interface VideoPickerViewController : UIViewController <AVCaptureFileOutputRecordingDelegate> {
    
    NSTimer *_countdownTimer;
    NSDate *_startDate;
}

@property (nonatomic, assign) id<NuovoViewControllerDelegate> nuovoViewControllerDelegate;
@property (nonatomic, retain) IBOutlet UIView *cameraView;
@property (nonatomic, retain) IBOutlet UILabel *countdownLabel;
@property (nonatomic, retain) NSString *moviePath;

- (void)startVideoCapture;
- (void)stopVideoCapture;

- (void)refreshCountdown:(id)sender;

@end
