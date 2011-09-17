//
//  UserNumberViewController.m
//  HackAzure
//
//  Created by Marco Gasparetto on 17/09/11.
//  Copyright 2011 Superpartes. All rights reserved.
//

#import "UserNumberViewController.h"
#import "AddressBookManager.h"

@implementation UserNumberViewController

@synthesize userNumberTextField;

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    AddressBookManager *abManager = [[AddressBookManager alloc] init];
    self.userNumberTextField.text = abManager.userNumber;
    [abManager release];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    AddressBookManager *abManager = [[AddressBookManager alloc] init];
    abManager.userNumber = self.userNumberTextField.text;
    [abManager release];
    
    self.userNumberTextField = nil;
}

@end
