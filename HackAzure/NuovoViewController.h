//
//  NuovoViewController.h
//  HackAzure
//
//  Created by Massimo Oliviero on 9/17/11.
//  Copyright 2011 App3. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddressBookManager.h"
#import "WACloudStorageClient.h"

@protocol NuovoViewControllerDelegate <NSObject>

- (void)dismissVideoPicker:(id)sender;

@end


@interface NuovoViewController : UIViewController<WACloudStorageClientDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, NuovoViewControllerDelegate> {
    WABlobContainer *selectedContainer;
    WACloudStorageClient *client;
}

@property (nonatomic, retain, readwrite) IBOutlet UITextField *destinatario;
@property (nonatomic, retain, readwrite) IBOutlet UITextView *messaggio;
@property (nonatomic, retain) WABlobContainer *selectedContainer;
@property (nonatomic, retain, readwrite)  NSString *dest;


- (IBAction)sendPressed:(id)sender;
- (IBAction)transparentButtonPressed:(id)sender;
- (IBAction)addVideoPressed:(id)sender;

@end
