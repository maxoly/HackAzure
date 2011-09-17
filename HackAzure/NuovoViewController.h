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
@interface NuovoViewController : UIViewController<WACloudStorageClientDelegate> {
    WACloudStorageClient *client;
}

@property (nonatomic, retain, readwrite) IBOutlet UITextField *destinatario;
@property (nonatomic, retain, readwrite) IBOutlet UITextView *messaggio;
@property (nonatomic, retain, readwrite) IBOutlet UIButton *invia;


- (IBAction)inviaPressed:(id)sender;
- (IBAction)suka:(id)sender;
@end
