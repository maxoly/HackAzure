//
//  RootViewController.m
//  HackAzure
//
//  Created by Marco Gasparetto on 17/09/11.
//  Copyright 2011 App3. All rights reserved.
//

#import "RootViewController.h"
#import "HackAzureAppDelegate.h"
#import "WAAuthenticationCredential.h"

#define sim @"3289433148"
@implementation RootViewController

@synthesize entityList;

- (void)viewDidLoad
{
    WAConfiguration* config = [WAConfiguration sharedConfiguration];	
    HackAzureAppDelegate *appDelegate = (HackAzureAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    appDelegate.authenticationCredential = [WAAuthenticationCredential credentialWithAzureServiceAccount:config.accountName accessKey:config.accessKey];
    
    [super viewDidLoad];
	
	tableClient = [[WACloudStorageClient storageClientWithCredential:appDelegate.authenticationCredential] retain];
	tableClient.delegate = self;
    

    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [tableClient peekQueueMessages:@"gvvv" fetchCount:1000];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.entityList count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    WAQueueMessage *queueMessage = [self.entityList objectAtIndex:indexPath.row];
    
    // Configure the cell.
    cell.textLabel.text = queueMessage.messageText;
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc
{
    [tableClient release];
    [entityList release];
    
    [super dealloc];
}


#pragma mark - CloudStorageClientDelegate methods

- (void)storageClient:(WACloudStorageClient *)client didFailRequest:request withError:error
{
	//[self showError:error];
}

- (void)storageClient:(WACloudStorageClient *)client didFetchEntities:(NSArray *)entities fromTableNamed:(NSString *)tableName
{
	self.entityList = [[entities mutableCopy] autorelease];
	if ([entities count] == 0)
	{
		self.navigationItem.rightBarButtonItem = nil;
	}
	[self.tableView reloadData];
}

- (void)storageClient:(WACloudStorageClient *)client didPeekQueueMessages:(NSArray *)queueMessages
{
	self.entityList = [[queueMessages mutableCopy] autorelease];
	[self.tableView reloadData];
}

@end
