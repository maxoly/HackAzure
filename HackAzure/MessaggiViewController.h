//
//  RootViewController.h
//  HackAzure
//
//  Created by Marco Gasparetto on 17/09/11.
//  Copyright 2011 App3. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WACloudStorageClient.h"
#import "Message.h"
#import "AddressBookManager.h"

@interface MessaggiViewController : UITableViewController<WACloudStorageClientDelegate, NSFetchedResultsControllerDelegate>
{
    WACloudStorageClient*	tableClient;
    NSMutableArray*			entityList;
    NSTimer                 *timer;
    AddressBookManager      *address;
}

@property (nonatomic, retain, readwrite) IBOutlet UITableViewCell *cell;
@property (nonatomic, retain) NSArray *entityList;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) AddressBookManager *address;

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end
