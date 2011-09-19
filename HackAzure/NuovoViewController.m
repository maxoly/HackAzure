//
//  NuovoViewController.m
//  HackAzure
//
//  Created by Massimo Oliviero on 9/17/11.
//  Copyright 2011 App3. All rights reserved.
//

#import "NuovoViewController.h"
#import "HackAzureAppDelegate.h"
#import "VideoPickerViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation NuovoViewController

@synthesize messaggio;
@synthesize destinatario;
@synthesize dest;
@synthesize selectedContainer;

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
    [super dealloc];
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    HackAzureAppDelegate *appDelegate = (HackAzureAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    client = [[WACloudStorageClient storageClientWithCredential:appDelegate.authenticationCredential] retain];
	client.delegate = self;
    
    self.navigationItem.title = @"Nuovo messaggio";

    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Invia" style:UIBarButtonItemStylePlain target:self action:@selector(sendPressed:)];
    self.navigationItem.rightBarButtonItem = sendButton;
    [sendButton release];

    self.messaggio.layer.borderColor = [[UIColor blackColor] CGColor];
    self.messaggio.layer.borderWidth = 1.f;
    self.messaggio.layer.cornerRadius = 8.f;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.messaggio = nil;
    self.destinatario = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    
     self.destinatario.text = self.dest;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:self.view.window]; 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:self.view.window]; 
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [super viewDidDisappear:animated];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        CGRect frame = self.view.frame;
        frame.size.height = 367 - (216 - 49);
        self.view.frame = frame;
    });
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        CGRect frame = self.view.frame;
        frame.size.height = 367;
        self.view.frame = frame;
    });
}

- (void)sendPressed:(id)sender
{
    AddressBookManager *a = [[AddressBookManager alloc] init];
    
    NSString *message = [NSString stringWithFormat:@"%@#%@", a.userNumber, self.messaggio.text];
    
    
    NSString *queueName = [NSString stringWithFormat:@"n%@", self.destinatario.text];
    
    [client addMessageToQueue:message queueName:queueName];
}

- (void)transparentButtonPressed:(id)sender
{
    [self.destinatario resignFirstResponder];
    [self.messaggio resignFirstResponder];
}

- (void)addVideoPressed:(id)sender
{
    VideoPickerViewController *viewController = [[VideoPickerViewController alloc] initWithNibName:@"VideoPickerViewController" bundle:nil];
    viewController.nuovoViewControllerDelegate = self;
    [self presentModalViewController:viewController animated:YES];
    [viewController release];
}

- (void)dismissVideoPicker:(id)sender
{
    VideoPickerViewController *viewController = (VideoPickerViewController *) sender;
    NSLog(@"%@", viewController.moviePath);
    
    [client fetchBlobContainerNamed:@"test" withCompletionHandler:^(WABlobContainer * cont, NSError * err) {
        
        NSData *video = [NSData dataWithContentsOfFile:viewController.moviePath];
        NSDate *date = [NSDate date];
        NSDateFormatter *fo = [[NSDateFormatter alloc] init];
        [fo setDateFormat:@"yyyy-MM-dd_hh-mm-ss.mp4"];
        
        [client addBlobToContainer:cont 
                          blobName:[fo stringFromDate:date]
                       contentData:video
                       contentType:@"video/mp4"
             withCompletionHandler:^(NSError* error) 
         {
             if(error)
             {
                // [self showError:error];
                 return;
             }
             
             [self dismissModalViewControllerAnimated:NO];
             [self.navigationController popViewControllerAnimated:YES];
         }];
    }];
  

}

@end
