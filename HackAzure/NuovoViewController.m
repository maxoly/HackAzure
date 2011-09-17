//
//  NuovoViewController.m
//  HackAzure
//
//  Created by Massimo Oliviero on 9/17/11.
//  Copyright 2011 App3. All rights reserved.
//

#import "NuovoViewController.h"
#import "HackAzureAppDelegate.h"

@implementation NuovoViewController

@synthesize messaggio;
@synthesize destinatario;
@synthesize invia;

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

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    HackAzureAppDelegate *appDelegate = (HackAzureAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    
    client = [[WACloudStorageClient storageClientWithCredential:appDelegate.authenticationCredential] retain];
	client.delegate = self;
    
    self.navigationItem.title = @"Nuovo messaggio";
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)inviaPressed:(id)sender
{
    NSString *message = [NSString stringWithFormat:@"%@#%@", self.destinatario.text, self.messaggio.text];
    NSString *queueName = [NSString stringWithFormat:@"n%@", self.destinatario.text];
    [client addMessageToQueue:message queueName:queueName];
}

- (IBAction)suka:(id)sender
{
    [self.destinatario resignFirstResponder];
    [self.messaggio resignFirstResponder];
}
@end
