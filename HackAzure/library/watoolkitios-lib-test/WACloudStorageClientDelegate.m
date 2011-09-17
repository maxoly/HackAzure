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

#import "WACloudStorageClientDelegate.h"

@implementation WACloudStorageClientDelegate

- (id)initForClient:(WACloudStorageClient*)client
{
	if((self = [super init]))
	{
		_client = client;
		_client.delegate = self;
	}
	
	return self;
}

- (void)markAsComplete
{
    _complete = YES;
}

- (void)waitForResponse
{
	[_client retain];
	[self retain];
	
	while(!_complete)
	{
		[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	}
    
	[_client release];
	[self autorelease];
    
    // reset...
    _complete = NO;
}

- (id)getResponse:(NSError**)error
{
    [self waitForResponse];
    
	if(_error)
	{
		*error = [_error autorelease];
        _error = nil; // reset...
		return nil;
	}
	
	id r = [_result autorelease];
    _result = nil;
    return r;
}

+ (WACloudStorageClientDelegate*) createDelegateForClient:(WACloudStorageClient*)client
{
	return [[[self alloc] initForClient:client] autorelease];
}

- (void)storageClient:(WACloudStorageClient*)client didFailRequest:request withError:error
{
	_error = [error retain];
    _complete = YES;
}

- (void)storageClient:(WACloudStorageClient*)client didFetchBlobContainers:(NSArray*)containers
{
	_result = [containers retain];
	_complete = YES;
}

- (void)storageClient:(WACloudStorageClient*)client didAddBlobContainer:(NSString*)name
{
	_complete = YES;
}

- (void)storageClient:(WACloudStorageClient*)client didDeleteBlobContainer:(WABlobContainer *)container
{
	_complete = YES;
}

- (void)storageClient:(WACloudStorageClient*)client didFetchBlobs:(NSArray*)blobs inContainer:(WABlobContainer *)container
{
	_result = [blobs retain];
	_complete = YES;
}

- (void)storageClient:(WACloudStorageClient*)client didFetchBlobData:(NSData*)data blob:(WABlob*)blob
{
	_result = [data retain];
	_complete = YES;
}

- (void)storageClient:(WACloudStorageClient *)client didAddBlobToContainer:(WABlobContainer *)container blobName:(NSString *)blobName
{
    _complete = YES;
}

- (void)storageClient:(WACloudStorageClient*)client didDeleteBlob:(WABlob*)blob
{
    _complete = YES;
}

- (void)storageClient:(WACloudStorageClient *)client didFetchTables:(NSArray *)tables
{
	_result = [tables retain];
	_complete = YES;
}

- (void)storageClient:(WACloudStorageClient *)client didCreateTableNamed:(NSString *)tableName
{
	_complete = YES;
}

- (void)storageClient:(WACloudStorageClient *)client didDeleteTableNamed:(NSString *)tableName
{
	_complete = YES;
}

- (void)storageClient:(WACloudStorageClient *)client didFetchEntities:(NSArray *)entities fromTableNamed:(NSString *)tableName
{
	_result = [entities retain];
	_complete = YES;
}

- (void)storageClient:(WACloudStorageClient *)client didInsertEntity:(WATableEntity *)entity;
{
	_complete = YES;
}

- (void)storageClient:(WACloudStorageClient *)client didUpdateEntity:(WATableEntity *)entity;
{
	_complete = YES;
}

- (void)storageClient:(WACloudStorageClient *)client didMergeEntity:(WATableEntity *)entity;
{
    _complete = YES;
}

- (void)storageClient:(WACloudStorageClient *)client didDeleteEntity:(WATableEntity *)entity
{
    _complete = YES;
}

@end
