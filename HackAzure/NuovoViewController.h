//
//  NuovoViewController.h
//  HackAzure
//
//  Created by Massimo Oliviero on 9/17/11.
//  Copyright 2011 App3. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WACloudStorageClient.h"

@protocol NuovoViewControllerDelegate <NSObject>

- (void)dismissVideoPicker:(id)sender;

@end


@interface NuovoViewController : UIViewController<WACloudStorageClientDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, NuovoViewControllerDelegate> {

    WACloudStorageClient *client;
}

@property (nonatomic, retain, readwrite) IBOutlet UITextField *destinatario;
@property (nonatomic, retain, readwrite) IBOutlet UITextView *messaggio;

- (IBAction)sendPressed:(id)sender;
- (IBAction)transparentButtonPressed:(id)sender;
- (IBAction)addVideoPressed:(id)sender;

@end
