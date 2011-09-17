//
//  RootViewController.h
//  HackAzure
//
//  Created by Marco Gasparetto on 17/09/11.
//  Copyright 2011 App3. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WACloudStorageClient.h"

@interface MessaggiViewController : UITableViewController<WACloudStorageClientDelegate>
{
    WACloudStorageClient*	tableClient;
    NSMutableArray*			entityList;
}

@property (nonatomic, retain) NSArray *entityList;

@end
