/*
 Copyright 2010 Microsoft Corp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "watoolkitios_lib_test.h"
#import "WACloudStorageClient.h"
#import "WAAuthenticationCredential.h"
#import "WACloudStorageClientDelegate.h"
#import "WATableFetchRequest.h"
#import "WATableEntity.h"
#import "WAQueue.h"
#import "WAQueueMessage.h"

/*

// Tests for blob related functions through proxy
#define TEST_FETCH_BLOBCONTAINERS_BLOBS_PROXY

// Tests for blob related functions
#define TEST_FETCH_BLOB_CONTAINERS
#define TEST_ADD_DELETE_BLOB_CONTAINER
#define TEST_ADD_BLOB

// Tests for table related functions for direct connection
#define TEST_FETCH_TABLES
#define TEST_ADD_DELETE_TABLE
#define TEST_FETCH_TABLE_ENTITIES
#define TEST_FETCH_TABLE_ENTITIES_WITH_PREDICATE
#define TEST_INSERT_TABLE_ENTITY
#define TEST_UPDATE_TABLE_ENTITY
#define TEST_MERGE_TABLE_ENTITY
#define TEST_DELETE_TABLE_ENTITY

// Tests for table related functions through proxy
#define TEST_FETCH_TABLES_PROXY
#define TEST_ADD_DELETE_TABLE_PROXY
#define TEST_FETCH_TABLE_ENTITIES_PROXY
#define TEST_FETCH_TABLE_ENTITIES_WITH_PREDICATE_PROXY
#define TEST_INSERT_TABLE_ENTITY_PROXY
#define TEST_UPDATE_TABLE_ENTITY_PROXY
#define TEST_MERGE_TABLE_ENTITY_PROXY
#define TEST_DELETE_TABLE_ENTITY_PROXY

// Tests for queue related functions
#define TEST_FETCH_QUEUES
#define TEST_ADD_DELETE_QUEUE
#define TEST_FETCH_QUEUE_MESSAGES

// Testfor queue related functions through proxy
#define TEST_FETCH_QUEUES_PROXY
#define TEST_ADD_DELETE_QUEUE_PROXY
#define TEST_FETCH_QUEUE_MESSAGES_PROXY	*/

// Account details for testing
NSString *account = @"<your account>";
NSString *accessKey = @"<your access key>";
NSString *proxyURL = @"https://<proxyhost>.cloudapp.net";
NSString *proxyUsername = @"proxy user name";
NSString *proxyPassword = @"proxy password";

// Use for test setup
WAAuthenticationCredential *directCredential;
WACloudStorageClient *directClient;
WACloudStorageClientDelegate *directDelegate;

WAAuthenticationCredential *proxyCredential;
WACloudStorageClient *proxyClient;
WACloudStorageClientDelegate *proxyDelegate;

// Used for container and table cleanup
NSString *unitTestContainerName = @"unitestcontainer";
NSString *unitTestQueueName = @"unittestqueue";
NSString *unitTestTableName = @"unittesttable";
NSString *randomContainerNameString;
NSString *randomQueueNameString;
NSString *randomTableNameString;
int containerCount = 0;
int tableCount = 0;

@implementation watoolkitios_lib_test

- (void)setUp
{
    // Setup the direct credentials
    directCredential = [WAAuthenticationCredential credentialWithAzureServiceAccount:account accessKey:accessKey];
    
    // Setup the proxy credentials
    NSError *error = nil;
    proxyCredential = [WAAuthenticationCredential authenticateCredentialSynchronousWithProxyURL:[NSURL URLWithString:proxyURL] user:proxyUsername password:proxyPassword error:&error];
    STAssertNil(error, @"There was an error authenticating against the proxy server: %@",[error localizedDescription]);

    // Setup the direct client and delegate
    directClient = [WACloudStorageClient storageClientWithCredential:directCredential];
    directDelegate = [WACloudStorageClientDelegate createDelegateForClient:directClient];

    // Setup the proxy client and delegate
    proxyClient = [WACloudStorageClient storageClientWithCredential:proxyCredential];
    proxyDelegate = [WACloudStorageClientDelegate createDelegateForClient:proxyClient];

    // Setup some random strings for unit tests tables, containers, and queues
    randomTableNameString = [NSString stringWithFormat:@"%@%d",unitTestTableName,arc4random() % 1000];
    randomContainerNameString = [NSString stringWithFormat:@"%@%d",unitTestContainerName,arc4random() % 1000];
    randomQueueNameString = [NSString stringWithFormat:@"%@%d",unitTestQueueName,arc4random() % 1000];
    
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

/*
 * Tests for Blob Storage via Direct Connection
 */

#ifdef TEST_FETCH_BLOB_CONTAINERS
- (void)testFetchBlobContainers_WithCompletionHandler_ReturnsContainerList 
{    
    NSLog(@"Executing TEST_FETCH_BLOB_CONTAINERS");
    [directClient fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         [directDelegate markAsComplete];
     }];
    
    [directDelegate waitForResponse];
}
#endif

#ifdef TEST_ADD_DELETE_BLOB_CONTAINER
-(void)testAddDeleteBlobContainer_WithCompletionHandler_ContainerAddedAndDeleted
{    
    NSLog(@"Executing TEST_ADD_DELETE_BLOB_CONTAINER");
    [directClient fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         containerCount = [containers count];
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient addBlobContainerNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from addBlobContainer: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         STAssertTrue((containerCount + 1 == [containers count] ),@"A new container doesn't appear to be added.");
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteBlobContainerNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteBlobContainer: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         STAssertTrue((containerCount == [containers count] ),@"Unit test container doesn't appear to be deleted.");
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}
#endif

#ifdef TEST_ADD_BLOB
-(void)testAddBlob_WithCompletionHandler_BlobAdded
{
    NSLog(@"Executing TEST_ADD_BLOB");
    
    [directClient addBlobContainerNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from addBlobContainer: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    NSLog(@"container added: %@", randomContainerNameString);
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:@"cloud" ofType:@"jpg"];
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    __block WABlobContainer *mycontainer;
    [directClient fetchBlobContainerNamed:randomContainerNameString WithCompletionHandler:^(WABlobContainer *container, NSError *error)
     {
         [directDelegate markAsComplete];
         [directClient addBlobToContainer:container blobName:@"cloud.jpg" contentData:data contentType:@"image/jpeg" withCompletionHandler:^(NSError *error)
          {
              mycontainer = container;
              STAssertNil(error, @"Error returned by addBlob: %@", [error localizedDescription]);
              [directDelegate markAsComplete];
          }];
         [directDelegate waitForResponse];
         
     }];
    [directDelegate waitForResponse];
    
    [directClient fetchBlobs:mycontainer withCompletionHandler:^(NSArray *blobs, NSError *error)
     {
         STAssertNil(error, @"Error returned by getBlobs: %@", [error localizedDescription]);
         STAssertTrue([blobs count] == 1, @"%i blobs were returned instead of 1",[blobs count]);         
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteBlobContainer:mycontainer withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteBlobContainer: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
}
#endif

/*
 * Tests for Table Storage via Direct Connection
 */

#ifdef TEST_FETCH_TABLES
-(void)testFetchTables_WithCompletionHandler_ReturnsTableList
{
    NSLog(@"Executing TEST_FETCH_TABLES");
    
    [directClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         [directDelegate markAsComplete];
     }];
	
	[directDelegate waitForResponse];	
}
#endif

#ifdef TEST_ADD_DELETE_TABLE
-(void)testAddDeleteTable_WithCompletionHandler_TableAddedAndDeleted
{
    NSLog(@"Executing TEST_ADD_DELETE_TABLE");
    
    [directClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         tableCount = [tables count];
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient createTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         STAssertTrue((tableCount + 1) == [tables count],@"Table didn't appear to be added."); 
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         STAssertTrue(tableCount == [tables count],@"Table didn't appear to be deleted."); 
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}
#endif

#ifdef TEST_FETCH_TABLE_ENTITIES
-(void)testFetchTableEntities_WithCompletionHandler_ReturnsTableEntities
{
    NSLog(@"Executing TEST_FETCH_TABLE_ENTITIES");
    
    WATableFetchRequest *fetchRequest = [WATableFetchRequest fetchRequestForTable:@"Developers"];
    [directClient fetchEntities:fetchRequest withCompletionHandler:^(NSArray *entities, NSError *error)
     {
         STAssertNil(error, @"Error returned by getEntities: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}
#endif

#ifdef TEST_FETCH_TABLE_ENTITIES_WITH_PREDICATE
-(void)testFetchTableEntitiesWithPredicate_WithCompletionHandler_ReturnsFilteredTableEntities
{
    NSLog(@"Executing TEST_FETCH_TABLE_ENTITIES_WITH_PREDICATE");
    
    // first create a table to test against
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    // insert an entry
    WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"Steve" forKey:@"Name"];
    
    [directClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    NSError *error = nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"Name = 'Steve' || Name = 'Eric' || Name = 'Ling'"];
    WATableFetchRequest* fetchRequest = [WATableFetchRequest fetchRequestForTable:randomTableNameString predicate:predicate error:&error];
	STAssertNil(error, @"Predicate parser error: %@", [error localizedDescription]);
    
    [directClient fetchEntities:fetchRequest withCompletionHandler:^(NSArray * entities, NSError * error) {
        STAssertNil(error, @"Error returned by getEntitiesFromTable: %@", [error localizedDescription]);
        STAssertNotNil(entities, @"getEntitiesFromTable returned nil");
        STAssertTrue(entities.count == 1, @"getEntitiesFromTable returned incorrect number of entities");
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}
#endif

#ifdef TEST_INSERT_TABLE_ENTITY
-(void)testInsertTableEntity_withCompletionHandler_InsertsEntityIntoTable
{
    NSLog(@"Executing TEST_INSERT_TABLE_ENTITY");
    
    // first create a table to test against
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
    
    [directClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Clean up after ourselves
    [directClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by deleteEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}
#endif

#ifdef TEST_UPDATE_TABLE_ENTITY
-(void)testUpdateTableEntity_withCompletionHandler_UpdatesEntityInTable
{
    NSLog(@"Executing TEST_UPDATE_TABLE_ENTITY");

    // first create a table to test against
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"299" forKey:@"Price"];
    
	// Setup before we run the actual test
    [directClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Now run the test
	[testEntity setObject:@"299" forKey:@"Price"];
    [directClient updateEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by updateEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Clean up after ourselves
    [directClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Teardown: Error returned by deleteEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}
#endif

#ifdef TEST_MERGE_TABLE_ENTITY
-(void)testMergeTableEntity_WithCompletionHandler_MergesExistingTableEntity
{
    NSLog(@"Executing TEST_MERGE_TABLE_ENTITY");
    
    // first create a table to test against
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"399" forKey:@"Price"];
	
	// Setup before we run the actual test
    [directClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Now run the test
	[testEntity setObject:@"399" forKey:@"Price"];
    [directClient mergeEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by mergeEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Clean up after ourselves
    [directClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Teardown: Error returned by deleteEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}
#endif

#ifdef TEST_DELETE_TABLE_ENTITY
-(void)testDeleteTableEntity_WithCompletionHandler_TableEntityIsDeleted
{
    NSLog(@"Executing TEST_DELETE_TABLE_ENTITY");
    
    // first create a table to test against
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
	
	// Setup before we run the actual test
    [directClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
	// Now run the test
    [directClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by deleteEntity: %@", [error localizedDescription]);
		 [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
    
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}
#endif

/*
 * Tests for Queue Storage via Direct Connection
 */

#ifdef TEST_FETCH_QUEUES
-(void)testFetchQueues_WithCompletionHandler_ReturnsListOfQueues 
{
    NSLog(@"Executing TEST_FETCH_QUEUES");
    
    [directClient fetchQueuesWithCompletionHandler:^(NSArray* queues, NSError* error)
     {
         STAssertNil(error, @"Error returned from fetchQueue: %@",[error localizedDescription]);
         STAssertTrue([queues count] > 0, @"No queues were found under this account");
         [directDelegate markAsComplete];
     }];
	
	[directDelegate waitForResponse];
}
#endif

#ifdef TEST_ADD_DELETE_QUEUE
-(void)testAddDeleteQueue_WithCompletionHandler_QueueAddedAndDeleted
{
    NSLog(@"Executing TEST_ADD_DELETE_QUEUE");
    
    [directClient addQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
        
    }];
    [directDelegate waitForResponse];
    
    [directClient deleteQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}
#endif

#ifdef TEST_FETCH_QUEUE_MESSAGES
-(void)testFetchQueueMessages_WithCompletionHandler_QueueMessageAddedAndReturned 
{
    NSLog(@"Executing TEST_FETCH_QUEUE_MESSAGES");
    
    [directClient addQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
        
    }];
    [directDelegate waitForResponse];
    
    [directClient addMessageToQueue:@"My Message test" queueName:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from adding message to Queue: %@",[error localizedDescription]);
        [directDelegate markAsComplete];
     }];
	[directDelegate waitForResponse];
    
    [directClient fetchQueueMessages:randomQueueNameString withCompletionHandler:^(NSArray* queueMessages, NSError* error)
     {
         STAssertNil(error, @"Error returned from getQueueMessages: %@",[error localizedDescription]);
         STAssertTrue([queueMessages count] > 0, @"No queueMessages were found under this account");
         [directDelegate markAsComplete];
     }];
	[directDelegate waitForResponse];
    
    [directClient deleteQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
         [directDelegate markAsComplete];
     }];
    [directDelegate waitForResponse];
}

#endif

/*
 * Tests for Blob Storage via the Proxy
 */

#ifdef TEST_FETCH_BLOBCONTAINERS_BLOBS_PROXY
-(void)testFetchBlobContainerBlobsProxy_WithCompletionHandler
{
    
    NSLog(@"Executing TEST_FETCH_BLOBCONTAINERS_PROXY");
    __block WABlobContainer *mycontainer;
    [proxyClient fetchBlobContainersWithCompletionHandler:^(NSArray *containers, NSError *error)
     {
         STAssertNil(error, @"Error returned from fetchBlobContainersWithCompletionHandler: %@",[error localizedDescription]);
         STAssertTrue([containers count] > 0, @"No containers were found under this account");  // assuming that this is an account with at least one container
         mycontainer = [containers objectAtIndex:0];
         [proxyDelegate markAsComplete];
         
         NSLog(@"Executing TEST_FETCH_BLOBS_THROUGH_PROXY");
         [proxyClient fetchBlobs:mycontainer withCompletionHandler:^(NSArray *blobs, NSError *error)
          {
              STAssertNil(error, @"Error returned by getBlobs: %@", [error localizedDescription]);
              STAssertTrue([blobs count] > 0, @"%i blobs were returned instead of 1",[blobs count]);         
              [proxyDelegate markAsComplete];
          }];
         [proxyDelegate waitForResponse];
         
     }];    
    [proxyDelegate waitForResponse];
    
    NSLog(@"Executing TEST_ADD_BLOB_TO_CONTAINER_THROUGH_PROXY");
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:@"cloud" ofType:@"jpg"];
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    [proxyClient addBlobToContainer:mycontainer blobName:@"cloud.jpg" contentData:data contentType:@"image/jpeg" withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by addBlob: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    NSLog(@"Dealy 5 seconds for adding blob data to be done in Azure Cloud!");
    NSDate *delay = [NSDate dateWithTimeIntervalSinceNow: 0.05 ];
    [NSThread sleepUntilDate:delay];
    
}
#endif

/*
 * Tests for Table Storage via Proxy
 */

#ifdef TEST_FETCH_TABLES_PROXY
-(void)testFetchTablesProxy_WithCompletionHandler_ReturnsTableList
{
    NSLog(@"Executing TEST_FETCH_TABLES_PROXY");
    
    [proxyClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         [proxyDelegate markAsComplete];
     }];
	
	[proxyDelegate waitForResponse];	
}
#endif

#ifdef TEST_ADD_DELETE_TABLE_PROXY
-(void)testAddDeleteTableProxy_WithCompletionHandler_TableAddedAndDeleted
{
    NSLog(@"Executing TEST_ADD_DELETE_TABLE_PROXY");
    
    [proxyClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         tableCount = [tables count];
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient createTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         STAssertTrue((tableCount + 1) == [tables count],@"Table didn't appear to be added."); 
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomContainerNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient fetchTablesWithCompletionHandler:^(NSArray* tables, NSError* error) 
     {
         STAssertNil(error, @"Error returned by getTables: %@", [error localizedDescription]);
         STAssertNotNil(tables, @"getTables returned nil");
         STAssertTrue(tables.count > 0, @"getTables returned no tables");
         STAssertTrue(tableCount == [tables count],@"Table didn't appear to be deleted."); 
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}
#endif

#ifdef TEST_FETCH_TABLE_ENTITIES_PROXY
-(void)testFetchTableEntitiesProxy_WithCompletionHandler_ReturnsTableEntities
{
    NSLog(@"Executing TEST_FETCH_TABLE_ENTITIES_PROXY");
    
    WATableFetchRequest *fetchRequest = [WATableFetchRequest fetchRequestForTable:@"Developers"];
    [proxyClient fetchEntities:fetchRequest withCompletionHandler:^(NSArray *entities, NSError *error)
     {
         STAssertNil(error, @"Error returned by getEntities: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}
#endif

#ifdef TEST_FETCH_TABLE_ENTITIES_WITH_PREDICATE_PROXY
-(void)testFetchTableEntitiesWithPredicateProxy_WithCompletionHandler_ReturnsFilteredTableEntities
{
    NSLog(@"Executing TEST_FETCH_TABLE_ENTITIES_WITH_PREDICATE_PROXY");
    
    // first create a table to test against
    [proxyClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    // insert an entry
    WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"Steve" forKey:@"Name"];
    
    [proxyClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    NSError *error = nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"Name = 'Steve' || Name = 'Eric' || Name = 'Ling'"];
    WATableFetchRequest* fetchRequest = [WATableFetchRequest fetchRequestForTable:randomTableNameString predicate:predicate error:&error];
	STAssertNil(error, @"Predicate parser error: %@", [error localizedDescription]);
    
    [proxyClient fetchEntities:fetchRequest withCompletionHandler:^(NSArray * entities, NSError * error) {
        STAssertNil(error, @"Error returned by getEntitiesFromTable: %@", [error localizedDescription]);
        STAssertNotNil(entities, @"getEntitiesFromTable returned nil");
        STAssertTrue(entities.count == 1, @"getEntitiesFromTable returned incorrect number of entities");
        [proxyDelegate markAsComplete];
    }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}
#endif

#ifdef TEST_INSERT_TABLE_ENTITY_PROXY
-(void)testInsertTableEntityProxy_withCompletionHandler_InsertsEntityIntoTable
{
    NSLog(@"Executing TEST_INSERT_TABLE_ENTITY_PROXY");
    
    // first create a table to test against
    [proxyClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
    
    [proxyClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by insertEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Clean up after ourselves
    [proxyClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by deleteEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}
#endif

#ifdef TEST_UPDATE_TABLE_ENTITY_PROXY
-(void)testUpdateTableEntityProxy_withCompletionHandler_UpdatesEntityInTable
{
    NSLog(@"Executing TEST_UPDATE_TABLE_ENTITY_PROXY");
    
    // first create a table to test against
    [proxyClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"299" forKey:@"Price"];
    
	// Setup before we run the actual test
    [proxyClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Now run the test
	[testEntity setObject:@"299" forKey:@"Price"];
    [proxyClient updateEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by updateEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Clean up after ourselves
    [proxyClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Teardown: Error returned by deleteEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}
#endif

#ifdef TEST_MERGE_TABLE_ENTITY_PROXY
-(void)testMergeTableEntityProxy_WithCompletionHandler_MergesExistingTableEntity
{
    NSLog(@"Executing TEST_MERGE_TABLE_ENTITY_PROXY");
    
    // first create a table to test against
    [proxyClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"399" forKey:@"Price"];
	
	// Setup before we run the actual test
    [proxyClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Now run the test
	[testEntity setObject:@"399" forKey:@"Price"];
    [proxyClient mergeEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by mergeEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Clean up after ourselves
    [proxyClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Teardown: Error returned by deleteEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}
#endif

#ifdef TEST_DELETE_TABLE_ENTITY_PROXY
-(void)testDeleteTableEntityProxy_WithCompletionHandler_TableEntityIsDeleted
{
    NSLog(@"Executing TEST_DELETE_TABLE_ENTITY_PROXY");
    
    // first create a table to test against
    [proxyClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	WATableEntity *testEntity = [WATableEntity createEntityForTable:randomTableNameString];
	testEntity.partitionKey = @"a";
	testEntity.rowKey = @"01021972";
	[testEntity setObject:@"199" forKey:@"Price"];
	
	// Setup before we run the actual test
    [proxyClient insertEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
	// Now run the test
    [proxyClient deleteEntity:testEntity withCompletionHandler:^(NSError *error)
     {
		 STAssertNil(error, @"Error returned by deleteEntity: %@", [error localizedDescription]);
		 [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
    
    [proxyClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}
#endif

/* 
 * Tests for Queue Storage via the Proxy
 */

#ifdef TEST_FETCH_QUEUES_PROXY
-(void)testFetchQueuesProxy_WithCompletionHandler_ReturnsListOfQueues 
{
    NSLog(@"Executing TEST_FETCH_QUEUES_PROXY");
    
    [proxyClient fetchQueuesWithCompletionHandler:^(NSArray* queues, NSError* error)
     {
         STAssertNil(error, @"Error returned from fetchQueue: %@",[error localizedDescription]);
         STAssertTrue([queues count] > 0, @"No queues were found under this account");
         [proxyDelegate markAsComplete];
     }];
	
	[proxyDelegate waitForResponse];
}
#endif

#ifdef TEST_ADD_DELETE_QUEUE_PROXY
-(void)testAddDeleteQueueProxy_WithCompletionHandler_QueueAddedAndDeleted
{
    NSLog(@"Executing TEST_ADD_DELETE_QUEUE_PPOXY");
    NSLog(@"Adding Queue Named: %@", randomQueueNameString);
    [proxyClient addQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
        [proxyDelegate markAsComplete];
        
    }];
    [proxyDelegate waitForResponse];
    
    NSLog(@"Deleting Queue Named: %@", randomQueueNameString);
    [proxyClient deleteQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}
#endif

#ifdef TEST_FETCH_QUEUE_MESSAGES_PROXY
-(void)testFetchQueueMessagesProxy_WithCompletionHandler_QueueMessageAddedAndReturned 
{
    NSLog(@"Executing TEST_FETCH_QUEUE_MESSAGES_PROXY");
    NSLog(@"Adding Queue Named: %@", randomQueueNameString);
    [proxyClient addQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error) {
        STAssertNil(error, @"Error returned from addQueue: %@",[error localizedDescription]);
        [proxyDelegate markAsComplete];
        
    }];
    [proxyDelegate waitForResponse];
    
    [proxyClient addMessageToQueue:@"My Message test" queueName:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from adding message to Queue: %@",[error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
	[proxyDelegate waitForResponse];
    
    [proxyClient fetchQueueMessages:randomQueueNameString withCompletionHandler:^(NSArray* queueMessages, NSError* error)
     {
         STAssertNil(error, @"Error returned from getQueueMessages: %@",[error localizedDescription]);
         STAssertTrue([queueMessages count] > 0, @"No queueMessages were found under this account");
         [proxyDelegate markAsComplete];
     }];
	[proxyDelegate waitForResponse];
    
    NSLog(@"Deleting Queue Named: %@", randomQueueNameString);
    [proxyClient deleteQueueNamed:randomQueueNameString withCompletionHandler:^(NSError *error)
     {
         STAssertNil(error, @"Error returned from deleteQueue: %@",[error localizedDescription]);
         [proxyDelegate markAsComplete];
     }];
    [proxyDelegate waitForResponse];
}
#endif

@end
