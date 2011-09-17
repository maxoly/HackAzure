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

#import <Foundation/Foundation.h>
#import "WAAuthenticationCredential.h"
#import "WABlob.h"
#import "WABlobContainer.h"
#import "WATableEntity.h"
#import "WATableFetchRequest.h"
#import "WAQueueMessage.h"

@protocol WACloudStorageClientDelegate;

/*! The cloud storage client is used to invoke operations on, and return data from, Windows Azure storage. */
@interface WACloudStorageClient : NSObject
{
	WAAuthenticationCredential* _credential;
	id<WACloudStorageClientDelegate> _delegate;
}

@property (assign) id<WACloudStorageClientDelegate> delegate;

+ (void) ignoreSSLErrorFor:(NSString*)host;

/*! Returns a list of blob containers. */
- (void)fetchBlobContainers;
/*! Returns a list of blob containers. */
- (void)fetchBlobContainersWithCompletionHandler:(void (^)(NSArray*, NSError *))block;
/*! Returnva a blob container. */
- (void)fetchBlobContainerNamed:(NSString *)containerName;
/*! Returnva a blob container. */
- (void)fetchBlobContainerNamed:(NSString *)containerName withCompletionHandler:(void (^)(WABlobContainer *, NSError *))block;
/*! Adds a blob container, given a specified container name.  Returns error if the container already exists, or where the name is an invalid format.*/
- (BOOL)addBlobContainerNamed:(NSString *)containerName;
/*! Adds a blob container, given a specified container name.  Returns error if the container already exists, or where the name is an invalid format.*/
- (BOOL)addBlobContainerNamed:(NSString *)containerName withCompletionHandler:(void (^)(NSError *))block;
/*! Deletes a specified blob container. */
- (BOOL)deleteBlobContainer:(WABlobContainer *)container;
/*! Deletes a specified blob container. */
- (BOOL)deleteBlobContainer:(WABlobContainer *)container withCompletionHandler:(void (^)(NSError *))block;
/*! Deletes a specified blob container with a name. */
- (BOOL)deleteBlobContainerNamed:(NSString *)containerName;
/*! Deletes a specified blob container with a name. */
- (BOOL)deleteBlobContainerNamed:(NSString *)containerName withCompletionHandler:(void (^)(NSError *))block;
/*! Returns an array of blobs from the specified blob container. */
- (void)fetchBlobs:(WABlobContainer *)container;
/*! Returns an array of blobs from the specified blob container. */
- (void)fetchBlobs:(WABlobContainer *)container withCompletionHandler:(void (^)(NSArray *, NSError *))block;
/*! Returns the binary data (NSData) object for the specified blob. */
- (void)fetchBlobData:(WABlob *)blob;
/*! Returns the binary data (NSData) object for the specified blob. */
- (void)fetchBlobData:(WABlob *)blob withCompletionHandler:(void (^)(NSData *, NSError *))block;
/*! Adds a new blob to a container, given the name of the blob, binary data for the blob, and content type. */
- (void)addBlobToContainer:(WABlobContainer *)container blobName:(NSString *)blobName contentData:(NSData *)contentData contentType:(NSString*)contentType;
/*! Adds a new blob to a container, given the name of the blob, binary data for the blob, and content type. */
- (void)addBlobToContainer:(WABlobContainer *)container blobName:(NSString *)blobName contentData:(NSData *)contentData contentType:(NSString*)contentType withCompletionHandler:(void (^)(NSError *))block;
/*! Deletes a blob.  Returns error if the blob doesn't exist or could not be deleted. */
- (void)deleteBlob:(WABlob *)blob;
/*! Deletes a blob.  Returns error if the blob doesn't exist or could not be deleted. */
- (void)deleteBlob:(WABlob *)blob withCompletionHandler:(void (^)(NSError *))block;

/*! Returns a list of queues. */
- (void)fetchQueues;
/*! Returns a list of queues. */
- (void)fetchQueuesWithCompletionHandler:(void (^)(NSArray*, NSError *))block;
/*! Adds a queue, given a specified queue name. */
- (void)addQueueNamed:(NSString *)queueName;
/*! Adds a queue, given a specified queue name.  Returns error if the queue already exists, or where the name is an invalid format.*/
- (void)addQueueNamed:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block;
/*! Deletes a queue, given a specified queue name. */
- (void)deleteQueueNamed:(NSString *)queueName;
/*! Deletes a queue, given a specified queue name. Returns error if failed. */
- (void)deleteQueueNamed:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block;
/*! Gets a message, given a specified queue name. */
- (void)fetchQueueMessages:(NSString *)queueName;
/*! Gets a message, given a specified queue name. Returns error if failed. */
- (void)fetchQueueMessages:(NSString *)queueName withCompletionHandler:(void (^)(NSArray *, NSError *))block;
/*! Gets a single message from the specified queue. */
- (void)fetchQueueMessage:(NSString *)queueName;
/*! Gets a single message from the specified queue. Returns error if failed. */
- (void)fetchQueueMessage:(NSString *)queueName withCompletionHandler:(void (^)(WAQueueMessage *, NSError *))block;
/*! Gets a batch of messages from the specified queue. */
- (void)fetchQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount;
/*! Gets a batch of messages from the specified queue. Returns error if failed. */
- (void)fetchQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount withCompletionHandler:(void (^)(NSArray *, NSError *))block;
/*! Peeks a single message from the specified queue. Peek is like Get, but the message is not marked for removal. */
- (void)peekQueueMessage:(NSString *)queueName;
/*! Peeks a single message from the specified queue. Peek is like Get, but the message is not marked for removal. Returns error if failed. */
- (void)peekQueueMessage:(NSString *)queueName withCompletionHandler:(void (^)(WAQueueMessage *, NSError *))block;
/*! Peeks a batch of messages from the specified queue. Peek is like Get, but the message is not marked for removal. */
- (void)peekQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount;
/*! Peeks a batch of messages from the specified queue. Peek is like Get, but the message is not marked for removal. Returns error if failed. */
- (void)peekQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount withCompletionHandler:(void (^)(NSArray *, NSError *))block;
/*! Deletes a message, given a specified queue name and queueMessage. */
- (void)deleteQueueMessage:(WAQueueMessage *)queueMessage queueName:(NSString *)queueName;
/*! Deletes a message, given a specified queue name and queueMessage. Returns error if failed. */
- (void)deleteQueueMessage:(WAQueueMessage *)queueMessage queueName:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block;
/*! Puts a message into a queue, given a specified queue name and message. */
- (void)addMessageToQueue:(NSString *)message queueName:(NSString *)queueName;
/*! Puts a message into a queue, given a specified queue name and message. Returns error if failed. */
- (void)addMessageToQueue:(NSString *)message queueName:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block;

/*! Returns a list of tables. */
- (void)fetchTables;
/*! Returns a list of tables. */
- (void)fetchTablesWithCompletionHandler:(void (^)(NSArray *, NSError *))block;
/*! Creates a new table with a specified name. */
- (void)createTableNamed:(NSString *)newTableName;
/*! Creates a new table with a specified name. */
- (void)createTableNamed:(NSString *)newTableName withCompletionHandler:(void (^)(NSError *))block;
/*! Deletes a specifed table.  Returns error is the table doesn't exist or could not be deleted. */
- (void)deleteTableNamed:(NSString *)tableName;
/*! Deletes a specifed table.  Returns error is the table doesn't exist or could not be deleted. */
- (void)deleteTableNamed:(NSString *)tableName withCompletionHandler:(void (^)(NSError *))block;
/*! Returns the entities for a given table. */
- (void)fetchEntities:(WATableFetchRequest*)fetchRequest;
/*! Returns the entities for a given table. */
- (void)fetchEntities:(WATableFetchRequest*)fetchRequest withCompletionHandler:(void (^)(NSArray *, NSError *))block;
/*! Inserts a new entity into an existing table. */
- (BOOL)insertEntity:(WATableEntity *)newEntity;
/*! Inserts a new entity into an existing table. */
- (BOOL)insertEntity:(WATableEntity *)newEntity withCompletionHandler:(void (^)(NSError *))block;
/*! Updates an existing entity within a table. */
- (BOOL)updateEntity:(WATableEntity *)existingEntity;
/*! Updates an existing entity within a table. */
- (BOOL)updateEntity:(WATableEntity *)existingEntity withCompletionHandler:(void (^)(NSError *))block;
/*! Merges an existing entity within a table. */
- (BOOL)mergeEntity:(WATableEntity *)existingEntity;
/*! Merges an existing entity within a table. */
- (BOOL)mergeEntity:(WATableEntity *)existingEntity withCompletionHandler:(void (^)(NSError *))block;
/*! Deletes an existing entity within a table. */
- (BOOL)deleteEntity:(WATableEntity *)existingEntity;
/*! Merges an existing entity within a table. */
- (BOOL)deleteEntity:(WATableEntity *)existingEntity withCompletionHandler:(void (^)(NSError *))block;

/*! Initializes a new cloud storage client, based on a passed set of authentication credentials. */
+ (WACloudStorageClient*) storageClientWithCredential:(WAAuthenticationCredential*)credential;

@end

/*! The CloudStorageClientDelegate is a protocol for handling delegated requests from CloudStorageClient. */
@protocol WACloudStorageClientDelegate <NSObject>

@optional

/*! Called if a URL request failed. */
- (void)storageClient:(WACloudStorageClient *)client didFailRequest:(NSURLRequest*)request withError:(NSError *)error;

/*! Called when the client successfully returns a list of blob containers */
- (void)storageClient:(WACloudStorageClient *)client didFetchBlobContainers:(NSArray *)containers;
/*! Called when the client successfully returns a blob container */
- (void)storageClient:(WACloudStorageClient *)client didFetchBlobContainer:(WABlobContainer *)container;
/*! Called when the client successsfully adds a new blob container. */
- (void)storageClient:(WACloudStorageClient *)client didAddBlobContainerNamed:(NSString *)name;
/*! Called when the client successfully removes an existing blob container. */
- (void)storageClient:(WACloudStorageClient *)client didDeleteBlobContainer:(WABlobContainer *)name;
/*! Called when the client successfully removes an existing blob container. */
- (void)storageClient:(WACloudStorageClient *)client didDeleteBlobContainerNamed:(NSString *)name;
/*! Called when the client successfully returns blobs from an existing container. */
- (void)storageClient:(WACloudStorageClient *)client didFetchBlobs:(NSArray *)blobs inContainer:(WABlobContainer *)container;
/*! Called when the client successfully returns blob data for a given blob. */
- (void)storageClient:(WACloudStorageClient *)client didFetchBlobData:(NSData *)data blob:(WABlob *)blob;
/*! Called when the client successfully adds a blob to a specified container. */
- (void)storageClient:(WACloudStorageClient *)client didAddBlobToContainer:(WABlobContainer *)container blobName:(NSString *)blobName;
/*! Called when the client successfully deletes a blob. */
- (void)storageClient:(WACloudStorageClient *)client didDeleteBlob:(WABlob *)blob;

/*! Called when the client successfully add a queue */
- (void)storageClient:(WACloudStorageClient *)client didAddQueueNamed:(NSString *)queueName;
/*! Called when the client successfully removes an existing queue. */
- (void)storageClient:(WACloudStorageClient *)client didDeleteQueueNamed:(NSString *)queueName;
/*! Called when the client successfully returns a list of queues */
- (void)storageClient:(WACloudStorageClient *)client didFetchQueues:(NSArray *)queues;
/*! Called when the client successfully got a single message from the specified queue */
- (void)storageClient:(WACloudStorageClient *)client didFetchQueueMessage:(WAQueueMessage *)queueMessage;
/*! Called when the client successfully get messages from the specified queue */
- (void)storageClient:(WACloudStorageClient *)client didFetchQueueMessages:(NSArray *)queueMessages;
/*! Called when the client successfully peeked a single message from the specified queue */
- (void)storageClient:(WACloudStorageClient *)client didPeekQueueMessage:(WAQueueMessage *)queueMessage;
/*! Called when the client successfully peeked messages from the specified queue */
- (void)storageClient:(WACloudStorageClient *)client didPeekQueueMessages:(NSArray *)queueMessages;
/*! Called when the client successfully delete a message from the specified queue */
- (void)storageClient:(WACloudStorageClient *)client didDeleteQueueMessage:(WAQueueMessage *)queueMessage queueName:(NSString *)queueName;
/*! Called when the client successfully put a message into the specified queue */
- (void)storageClient:(WACloudStorageClient *)client didAddMessageToQueue:(NSString *)message queueName:(NSString *)queueName;

/*! Called when the client successfully returns a list of tables. */
- (void)storageClient:(WACloudStorageClient *)client didFetchTables:(NSArray *)tables;
/*! Called when the client successfully creates a table. */
- (void)storageClient:(WACloudStorageClient *)client didCreateTableNamed:(NSString *)tableName;
/*! Called when the client successfully deletes a specified table. */
- (void)storageClient:(WACloudStorageClient *)client didDeleteTableNamed:(NSString *)tableName;
/*! Called when the client successfully returns a list of entities from a table. */
- (void)storageClient:(WACloudStorageClient *)client didFetchEntities:(NSArray *)entities fromTableNamed:(NSString *)tableName;

/*! Called when the client successfully inserts an entity into a table. */
- (void)storageClient:(WACloudStorageClient *)client didInsertEntity:(WATableEntity *)entity;
/*! Called when the client successfully updates an entity within a table. */
- (void)storageClient:(WACloudStorageClient *)client didUpdateEntity:(WATableEntity *)entity;
/*! Called when the client successfully merges an entity within a table. */
- (void)storageClient:(WACloudStorageClient *)client didMergeEntity:(WATableEntity *)entity;
/*! Called when the client successfully deletes an entity from a table. */
- (void)storageClient:(WACloudStorageClient *)client didDeleteEntity:(WATableEntity *)entity;


@end
