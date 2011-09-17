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

#import "WACloudStorageClient.h"
#import "WACloudURLRequest.h"
#import "WAContainerParser.h"
#import "WABlobParser.h"
#import "WABlob.h"
#import "CommonCrypto/CommonHMAC.h"
#import "WAAuthenticationCredential+Private.h"
#import "NSString+URLEncode.h"
#import "WAXMLHelper.h"
#import "WATableEntity.h"
#import "WAQueueParser.h"
#import "WAQueueMessageParser.h"
#import "WASimpleBase64.h"

void ignoreSSLErrorFor(NSString* host);

static NSString *CREATE_TABLE_REQUEST_STRING = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><entry xmlns:d=\"http://schemas.microsoft.com/ado/2007/08/dataservices\" xmlns:m=\"http://schemas.microsoft.com/ado/2007/08/dataservices/metadata\" xmlns=\"http://www.w3.org/2005/Atom\"><title /><updated>$UPDATEDDATE$</updated><author><name/></author><id/><content type=\"application/xml\"><m:properties><d:TableName>$TABLENAME$</d:TableName></m:properties></content></entry>";
static NSString *TABLE_INSERT_ENTITY_REQUEST_STRING = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><entry xmlns:d=\"http://schemas.microsoft.com/ado/2007/08/dataservices\" xmlns:m=\"http://schemas.microsoft.com/ado/2007/08/dataservices/metadata\" xmlns=\"http://www.w3.org/2005/Atom\"><title /><updated>$UPDATEDDATE$</updated><author><name /></author><id /><content type=\"application/xml\"><m:properties>$PROPERTIES$</m:properties></content></entry>";
static NSString *TABLE_UPDATE_ENTITY_REQUEST_STRING = @"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><entry xmlns:d=\"http://schemas.microsoft.com/ado/2007/08/dataservices\" xmlns:m=\"http://schemas.microsoft.com/ado/2007/08/dataservices/metadata\" xmlns=\"http://www.w3.org/2005/Atom\"><title /><updated>$UPDATEDDATE$</updated><author><name /></author><id>$ENTITYID$</id><content type=\"application/xml\"><m:properties>$PROPERTIES$</m:properties></content></entry>";

@interface WACloudStorageClient (Private)
- (void)privateGetQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount useBlockError:(BOOL)useBlockError peekOnly:(BOOL)peekOnly withBlock:(void (^)(NSArray *, NSError *))block;
@end

@interface WATableEntity (Private)

- (id)initWithDictionary:(NSMutableDictionary*)dictionary fromTable:(NSString*)tableName;
- (NSString*)propertyString;
- (NSString*)endpoint;

@end

@interface WATableFetchRequest (Private)

- (NSString*)endpoint;

@end

@implementation WACloudStorageClient

@synthesize delegate = _delegate;

#pragma mark Creation

- (id)initWithCredential:(WAAuthenticationCredential*)credential
{
	if((self = [super init]))
	{
		_credential = [credential retain];
	}
	
	return self;
}

+ (WACloudStorageClient*) storageClientWithCredential:(WAAuthenticationCredential*)credential
{
	return [[[self alloc] initWithCredential:credential] autorelease];
}

+ (void) ignoreSSLErrorFor:(NSString*)host
{
	ignoreSSLErrorFor(host);
}

- (void)prepareTableRequest:(WACloudURLRequest*)request
{
    [request setValue:@"2.0;NetFx" forHTTPHeaderField:@"MaxDataServiceVersion"];
    [request setValue:@"application/atom+xml,application/xml" forHTTPHeaderField:@"Accept"];
    [request setValue:@"NativeHost" forHTTPHeaderField:@"User-Agent"];
}

#pragma mark -
#pragma mark Queue API methods

- (void)fetchQueues
{
    [self fetchQueuesWithCompletionHandler:nil];
}

- (void)fetchQueuesWithCompletionHandler:(void (^)(NSArray*, NSError *))block
{
    WACloudURLRequest* request;
    if(_credential.usesProxy)
    {
        // 100ns intervals since 1/1/1970
        long long ticks = [[NSDate date] timeIntervalSince1970] * 10000000;
        // adjust relative to 1/1/0001
        ticks += 621355968000000000;                                        
        NSString *endpoint = [NSString stringWithFormat:@"?comp=list&incrementalSeed=%llu", ticks];
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue", nil];

        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
         {
             if(error)
             {
                 if(block)
                 {
                     block(nil, error);
                 }
                 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                 {
                     [_delegate storageClient:self didFailRequest:request withError:error];
                 }
                 return;
             }
             
             NSArray* queues = [WAQueueParser loadQueuesForProxy:doc];
             
             if(block)
             {
                 block(queues, nil);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFetchQueues:)])
             {
                 [_delegate storageClient:self didFetchQueues:queues];
             }
         }];
    }
    else
    {
        request = [_credential authenticatedRequestWithEndpoint:@"?comp=list" forStorageType:@"queue", nil];

        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
         {
             if(error)
             {
                 if(block)
                 {
                     block(nil, error);
                 }
                 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                 {
                     [_delegate storageClient:self didFailRequest:request withError:error];
                 }
                 return;
             }
             
             NSArray* queues = [WAQueueParser loadQueues:doc];
             
             if(block)
             {
                 block(queues, nil);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFetchQueues:)])
             {
                 [_delegate storageClient:self didFetchQueues:queues];
             }
         }];
    }
    
}


- (void)addQueueNamed:(NSString *)queueName
{
    [self addQueueNamed:queueName withCompletionHandler:nil];
}

- (void)addQueueNamed:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block
{
    queueName = [queueName lowercaseString];
    NSString* endpoint = [NSString stringWithFormat:@"/%@", [queueName URLEncode]];
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue" httpMethod:@"PUT", nil];
    
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
     {
         if(error)
         {
             if(block)
             {
                 block(error);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if(block)
         {
             block(nil);
         }
         else if([_delegate respondsToSelector:@selector(storageClient:didAddQueueNamed:)])
         {
             [_delegate storageClient:self didAddQueueNamed:queueName];
         }
     }];
}

- (void)deleteQueueNamed:(NSString *)queueName
{
    [self deleteQueueNamed:queueName withCompletionHandler:nil];
}

- (void)deleteQueueNamed:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block
{
    queueName = [queueName lowercaseString];
    NSString* endpoint = [NSString stringWithFormat:@"/%@", [queueName URLEncode]];
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue" httpMethod:@"DELETE", nil];
    
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
     {
         if(error)
         {
             if(block)
             {
                 block(error);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if(block)
         {
             block(nil);
         }
         else if([_delegate respondsToSelector:@selector(storageClient:didDeleteQueueNamed:)])
         {
             [_delegate storageClient:self didDeleteQueueNamed:queueName];
         }
     }];

}

- (void)fetchQueueMessage:(NSString *)queueName
{
	[self privateGetQueueMessages:queueName fetchCount:1 useBlockError:NO peekOnly:NO withBlock:^(NSArray* items, NSError* error) 
	 {
		 if(![_delegate respondsToSelector:@selector(storageClient:didFetchQueueMessage:)])
		 {
			 return;
		 }
		 
		 if(items.count >= 1)
		 {
			 [_delegate storageClient:self didFetchQueueMessage:[items objectAtIndex:0]];
		 }
		 else
		 {
			 [_delegate storageClient:self didFetchQueueMessage:nil];
		 }
	 }];
}

- (void)fetchQueueMessage:(NSString *)queueName withCompletionHandler:(void (^)(WAQueueMessage *, NSError *))block
{
	[self privateGetQueueMessages:queueName fetchCount:1 useBlockError:!!block peekOnly:NO withBlock:^(NSArray* items, NSError* error) 
	{
		if(error)
		{
			if(block)
			{
				block(nil, error);
			}
			else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
			{
				[_delegate storageClient:self didFailRequest:nil withError:error];
			}
			return;
		}
		
		if(block)
		{
			if(items.count >= 1)
			{
				block([items objectAtIndex:0], nil);
			}
			else
			{
				block(nil, nil);
			}
		}
		else if(![_delegate respondsToSelector:@selector(storageClient:didFetchQueueMessage:)])
		{
			if(items.count >= 1)
			{
				[_delegate storageClient:self didFetchQueueMessage:[items objectAtIndex:0]];
			}
			else
			{
				[_delegate storageClient:self didFetchQueueMessage:nil];
			}
		}
	}];
}

- (void)fetchQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount
{
	[self privateGetQueueMessages:queueName fetchCount:fetchCount useBlockError:NO peekOnly:NO withBlock:^(NSArray* items, NSError* error)
	 {
		 if(![_delegate respondsToSelector:@selector(storageClient:didFetchQueueMessages:)])
		 {
			 return;
		 }
		 
		 [_delegate storageClient:self didFetchQueueMessages:items];
	 }];
}

- (void)fetchQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount withCompletionHandler:(void (^)(NSArray *, NSError *))block
{
	[self privateGetQueueMessages:queueName fetchCount:fetchCount useBlockError:!!block peekOnly:NO withBlock:^(NSArray* items, NSError* error)
	 {
		 if(error)
		 {
			 if(block)
			 {
				 block(nil, error);
			 }
			 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
			 {
				 [_delegate storageClient:self didFailRequest:nil withError:error];
			 }
			 return;
		 }
		 
		 if(block)
		 {
			 block(items, nil);
		 }
		 else if(![_delegate respondsToSelector:@selector(storageClient:didFetchQueueMessages:)])
		 {
			 [_delegate storageClient:self didFetchQueueMessages:items];
		 }
	 }];
}

- (void)peekQueueMessage:(NSString *)queueName
{
	[self privateGetQueueMessages:queueName fetchCount:1 useBlockError:NO peekOnly:YES withBlock:^(NSArray* items, NSError* error) 
	 {
		 if(![_delegate respondsToSelector:@selector(storageClient:didPeekQueueMessage:)])
		 {
			 return;
		 }
		 
		 if(items.count >= 1)
		 {
			 [_delegate storageClient:self didPeekQueueMessage:[items objectAtIndex:0]];
		 }
		 else
		 {
			 [_delegate storageClient:self didPeekQueueMessage:nil];
		 }
	 }];
}

- (void)peekQueueMessage:(NSString *)queueName withCompletionHandler:(void (^)(WAQueueMessage *, NSError *))block
{
	[self privateGetQueueMessages:queueName fetchCount:1 useBlockError:!!block peekOnly:YES withBlock:^(NSArray* items, NSError* error) 
	 {
		 if(error)
		 {
			 if(block)
			 {
				 block(nil, error);
			 }
			 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
			 {
				 [_delegate storageClient:self didFailRequest:nil withError:error];
			 }
			 return;
		 }
		 
		 if(block)
		 {
			 if(items.count >= 1)
			 {
				 block([items objectAtIndex:0], nil);
			 }
			 else
			 {
				 block(nil, nil);
			 }
		 }
		 else if(![_delegate respondsToSelector:@selector(storageClient:didPeekQueueMessage:)])
		 {
			 if(items.count >= 1)
			 {
				 [_delegate storageClient:self didPeekQueueMessage:[items objectAtIndex:0]];
			 }
			 else
			 {
				 [_delegate storageClient:self didPeekQueueMessage:nil];
			 }
		 }
	 }];
}

- (void)peekQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount
{
	[self privateGetQueueMessages:queueName fetchCount:fetchCount useBlockError:NO peekOnly:YES withBlock:^(NSArray* items, NSError* error)
	 {
		 if(![_delegate respondsToSelector:@selector(storageClient:didPeekQueueMessages:)])
		 {
			 return;
		 }
		 
		 [_delegate storageClient:self didPeekQueueMessages:items];
	 }];
}

- (void)peekQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount withCompletionHandler:(void (^)(NSArray *, NSError *))block
{
	[self privateGetQueueMessages:queueName fetchCount:fetchCount useBlockError:!!block peekOnly:YES withBlock:^(NSArray* items, NSError* error)
	 {
		 if(error)
		 {
			 if(block)
			 {
				 block(nil, error);
			 }
			 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
			 {
				 [_delegate storageClient:self didFailRequest:nil withError:error];
			 }
			 return;
		 }
		 
		 if(block)
		 {
			 block(items, nil);
		 }
		 else if(![_delegate respondsToSelector:@selector(storageClient:didPeekQueueMessages:)])
		 {
			 [_delegate storageClient:self didPeekQueueMessages:items];
		 }
	 }];
}

- (void)fetchQueueMessages:(NSString *)queueName
{
    [self fetchQueueMessages:queueName withCompletionHandler:nil];
}

- (void)fetchQueueMessages:(NSString *)queueName withCompletionHandler:(void (^)(NSArray *, NSError *))block
{
    queueName = [queueName lowercaseString];
    NSString* endpoint = [NSString stringWithFormat:@"/%@/messages?numofmessages=32", [queueName URLEncode]];
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue", nil];

    [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
     {
         if(error)
         {
             if(block)
             {
                 block(nil, error);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         NSArray* queueMessages = [WAQueueMessageParser loadQueueMessages:doc];
         
         if(block)
         {
             block(queueMessages, nil);
         }
         else if([_delegate respondsToSelector:@selector(storageClient:didFetchQueueMessages:)])
         {
             [_delegate storageClient:self didFetchQueueMessages:queueMessages];
         }
     }];
}

- (void)deleteQueueMessage:(WAQueueMessage *)queueMessage queueName:(NSString *)queueName
{
    [self deleteQueueMessage:queueMessage queueName:queueName withCompletionHandler:nil];
}

- (void)deleteQueueMessage:(WAQueueMessage *)queueMessage queueName:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block
{
    queueName = [queueName lowercaseString];
    NSString* endpoint = [NSString stringWithFormat:@"/%@/messages/%@?popreceipt=%@", [queueName URLEncode], queueMessage.messageId, queueMessage.popReceipt];
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue" httpMethod:@"DELETE", nil];
    
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
     {
         if(error)
         {
             if(block)
             {
                 block(error);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if(block)
         {
             block(nil);
         }
         else if([_delegate respondsToSelector:@selector(storageClient:didDeleteQueueMessage:queueName:)])
         {
             [_delegate storageClient:self didDeleteQueueMessage:queueMessage queueName:queueName];
         }
     }];
}

- (void)addMessageToQueue:(NSString *)message queueName:(NSString *)queueName
{
    [self addMessageToQueue:message queueName:queueName withCompletionHandler:nil];

}

- (void)addMessageToQueue:(NSString *)message queueName:(NSString *)queueName withCompletionHandler:(void (^)(NSError *))block
{
    NSString* endpoint = [NSString stringWithFormat:@"/%@/messages", [queueName URLEncode]];
    NSString *queueMsgStart = @"<QueueMessage><MessageText>";
	NSString *queueMsgEnd = @"</MessageText></QueueMessage>";
    NSMutableString *escapedString = [NSMutableString stringWithString:message];
    [escapedString replaceOccurrencesOfString:@"&"  withString:@"&amp;"  options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
    [escapedString replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
    [escapedString replaceOccurrencesOfString:@"'"  withString:@"&#39;" options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
    [escapedString replaceOccurrencesOfString:@">"  withString:@"&gt;"   options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
    [escapedString replaceOccurrencesOfString:@"<"  withString:@"&lt;"   options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	NSData *encodedData = [escapedString dataUsingEncoding:NSUTF8StringEncoding]; 
    NSString* encodedString = [encodedData stringWithBase64EncodedData];
	NSString *queueMsg = [NSString stringWithFormat:@"%@%@%@", queueMsgStart, encodedString, queueMsgEnd];
	NSData *contentData = [queueMsg dataUsingEncoding:NSUTF8StringEncoding];
    WACloudURLRequest *request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue" httpMethod:@"POST" contentData:contentData contentType:@"text/xml", nil];
    
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest* request, NSError* error)
     {
         if(error)
         {
             if(block)
             {
                 block(error);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if(block)
         {
             block(nil);
         }
         else if([_delegate respondsToSelector:@selector(storageClient:didAddMessageToQueue:queueName:)])
         {
             [_delegate storageClient:self didAddMessageToQueue:message queueName:queueName];
         }
     }];
    
}

#pragma mark -
#pragma mark Blob API methods

- (void)fetchBlobContainers
{
    [self fetchBlobContainersWithCompletionHandler:nil];
}

- (void)fetchBlobContainersWithCompletionHandler:(void (^)(NSArray*, NSError*))block
{
    if(_credential.usesProxy)
    {
        WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:@"/SharedAccessSignatureService/container" forStorageType:@"blob", nil];
        
        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
         {
             if(error)
             {
                 if(block)
                 {
                     block(nil, error);
                 }
                 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                 {
                     [_delegate storageClient:self didFailRequest:request withError:error];
                 }
                 return;
             }
             
             NSArray* containers = [WAContainerParser loadContainersForProxy:doc];
             
             if(block)
             {
                 block(containers, nil);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobContainers:)])
             {
                 [_delegate storageClient:self didFetchBlobContainers:containers];
             }
         }];
    }
    else
    {
        WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:@"?comp=list&include=metadata" forStorageType:@"blob",
                                    @"x-ms-blob-type", @"BlockBlob", nil];
        
        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
         {
             if(error)
             {
                 if(block)
                 {
                     block(nil, error);
                 }
                 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                 {
                     [_delegate storageClient:self didFailRequest:request withError:error];
                 }
                 return;
             }
             
             NSArray* containers = [WAContainerParser loadContainers:doc];
             
             if(block)
             {
                 block(containers, nil);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobContainers:)])
             {
                 [_delegate storageClient:self didFetchBlobContainers:containers];
             }
         }];
    }
}

- (void)fetchBlobContainerNamed:(NSString *)containerName 
{
    [self fetchBlobContainerNamed:containerName withCompletionHandler:nil];
}

- (void)fetchBlobContainerNamed:(NSString *)containerName withCompletionHandler:(void (^)(WABlobContainer *, NSError *))block
{
    if(_credential.usesProxy)
    {
        WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:@"/SharedAccessSignatureService/container" forStorageType:@"blob", nil];
        
        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
         {
             if(error)
             {
                 if(block)
                 {
                     block(nil, error);
                 }
                 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                 {
                     [_delegate storageClient:self didFailRequest:request withError:error];
                 }
                 return;
             }
             
             NSArray* containers = [WAContainerParser loadContainersForProxy:doc];
             WABlobContainer *container = nil;
             for (WABlobContainer *tempContainer in containers) {
                 if ([tempContainer.name isEqualToString:[containerName lowercaseString]]) {
                     container = tempContainer;
                     break;
                 }
             }
             
             if(block)
             {
                 block(container, nil);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobContainer:)])
             {
                 [_delegate storageClient:self didFetchBlobContainer:container];
             }
         }];
    }
    else
    {
        WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:@"?comp=list&include=metadata" forStorageType:@"blob",
                                      @"x-ms-blob-type", @"BlockBlob", nil];
        
        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
         {
             if(error)
             {
                 if(block)
                 {
                     block(nil, error);
                 }
                 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                 {
                     [_delegate storageClient:self didFailRequest:request withError:error];
                 }
                 return;
             }
             
             NSArray* containers = [WAContainerParser loadContainers:doc];
             WABlobContainer *container = nil;
             for (WABlobContainer *tempContainer in containers) {
                 if ([tempContainer.name isEqualToString:[containerName lowercaseString]]) {
                     container = tempContainer;
                     break;
                 }
             }
             
             if(block)
             {
                 block(container, nil);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobContainer:)])
             {
                 [_delegate storageClient:self didFetchBlobContainer:container];
             }
         }];
    }
}

- (BOOL)addBlobContainerNamed:(NSString *)containerName
{
    return [self addBlobContainerNamed:containerName withCompletionHandler:nil];
}

- (BOOL)addBlobContainerNamed:(NSString *)containerName withCompletionHandler:(void (^)(NSError*))block
{
	if(_credential.usesProxy)
    {
        return NO;
    }
    
    containerName = [containerName lowercaseString];
    NSString* endpoint = [NSString stringWithFormat:@"/%@?restype=container", [containerName URLEncode]];
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob" httpMethod:@"PUT" contentData:[NSData data] contentType:nil, nil];

	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
     {
         if(error)
         {
             if(block)
             {
                 block(error);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if(block)
         {
             block(nil);
         }
         else if([_delegate respondsToSelector:@selector(storageClient:didAddBlobContainerNamed:)])
         {
             [_delegate storageClient:self didAddBlobContainerNamed:containerName];
         }
     }];
    
    return YES;
}

- (BOOL)deleteBlobContainer:(WABlobContainer *)container
{
    return [self deleteBlobContainer:container withCompletionHandler:nil];
}

- (BOOL)deleteBlobContainer:(WABlobContainer *)container withCompletionHandler:(void (^)(NSError*))block
{
    if(_credential.usesProxy)
    {
        return NO;
    }
    //NSString* containerName = [container.name lowercaseString];
    NSString *containerName = [[NSString stringWithFormat:@"%@", container.name] lowercaseString];
    NSString* endpoint = [NSString stringWithFormat:@"/%@?restype=container", [containerName URLEncode]];
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob" httpMethod:@"DELETE" contentData:[NSData data] contentType:nil, nil];
    	
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
     {
         if(error)
         {
             if(block)
             {
                 block(error);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if(block)
         {
             block(nil);
         }
         else if([_delegate respondsToSelector:@selector(storageClient:didDeleteBlobContainer:)])
         {
             [_delegate storageClient:self didDeleteBlobContainer:container];
         }
     }];

    
    return YES;
}

- (BOOL)deleteBlobContainerNamed:(NSString *)containerName
{
    return [self deleteBlobContainerNamed:containerName withCompletionHandler:nil];
}

- (BOOL)deleteBlobContainerNamed:(NSString *)containerName withCompletionHandler:(void (^)(NSError *))block
{
    if(_credential.usesProxy)
    {
        return NO;
    }
    containerName = [[NSString stringWithFormat:@"%@", containerName] lowercaseString];
    NSString* endpoint = [NSString stringWithFormat:@"/%@?restype=container", [containerName URLEncode]];
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob" httpMethod:@"DELETE" contentData:[NSData data] contentType:nil, nil];
    
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
     {
         if(error)
         {
             if(block)
             {
                 block(error);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if(block)
         {
             block(nil);
         }
         else if([_delegate respondsToSelector:@selector(storageClient:didDeleteBlobContainerNamed:)])
         {
             [_delegate storageClient:self didDeleteBlobContainerNamed:containerName];
         }
     }];
    
    
    return YES;
}

- (void)fetchBlobs:(WABlobContainer *)container
{
    [self fetchBlobs:container withCompletionHandler:nil];
}

- (void)fetchBlobs:(WABlobContainer *)container withCompletionHandler:(void (^)(NSArray*, NSError*))block
{
    if(_credential.usesProxy)
    {
        WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:@"/SharedAccessSignatureService/blob" forStorageType:@"blob",
                                    @"x-ms-blob-type", @"BlockBlob", nil];
        
        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
         {
             if(error)
             {
                 if(block)
                 {
                     block(nil, error);
                 }
                 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                 {
                     [_delegate storageClient:self didFailRequest:request withError:error];
                 }
                 return;
             }
             
             NSArray* items = [WABlobParser loadBlobsForProxy:doc container:container];
             
             if(block)
             {
                 block(items, nil);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobs:inContainer:)])
             {
                 [_delegate storageClient:self didFetchBlobs:items inContainer:container];
             }
         }];
    }
    else
    {
        NSString* containerName = container.name;
        NSString* endpoint = [NSString stringWithFormat:@"/%@?comp=list&restype=container", [containerName URLEncode]];
        WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob",
                                    @"x-ms-blob-type", @"BlockBlob", nil];
        
        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
         {
             if(error)
             {
                 if(block)
                 {
                     block(nil, error);
                 }
                 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                 {
                     [_delegate storageClient:self didFailRequest:request withError:error];
                 }
                 return;
             }
             
             NSArray* items = [WABlobParser loadBlobs:doc container:container];
             
             if(block)
             {
                 block(items, nil);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobs:inContainer:)])
             {
                 [_delegate storageClient:self didFetchBlobs:items inContainer:container];
             }
         }];
    }
}

- (void)fetchBlobData:(WABlob *)blob
{
    [self fetchBlobData:blob withCompletionHandler:nil];
}

- (void)fetchBlobData:(WABlob *)blob withCompletionHandler:(void (^)(NSData*, NSError*))block
{
    WACloudURLRequest* request;
	if(_credential.usesProxy)
    {
        request = [_credential authenticatedRequestWithEndpoint:@"/SharedAccessSignatureService/blob" forStorageType:@"blob", nil];

        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
         {
             if(error)
			 {
				 if(block)
				 {
					 block(nil, error);
				 }
				 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
				 {
					 [_delegate storageClient:self didFailRequest:request withError:error];
				 }
				 return;
			 }
			 
             NSArray* items = [WABlobParser loadBlobsForProxy:doc];
             WABlob* toBeDisplayedBlob = nil;
             for (WABlob *item in items) {
                 if ([item.name isEqualToString:blob.name]) {
                     toBeDisplayedBlob = item;
                     break;
                 }
             }
             NSString* endpoint = [NSString stringWithFormat:@"%@", toBeDisplayedBlob.URL];
             NSURL* serviceURL = [NSURL URLWithString:endpoint];
			 WACloudURLRequest* blobRequest = [WACloudURLRequest requestWithURL:serviceURL];
             [blobRequest fetchDataWithCompletionHandler:^(WACloudURLRequest* request, NSData* data, NSError* error)
              {
                  if(error)
                  {
                      if(block)
                      {
                          block(nil, error);
                      }
                      else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                      {
                          [_delegate storageClient:self didFailRequest:request withError:error];
                      }
                      return;
                  }
                  
                  if(block)
                  {
                      block(data, nil);
                  }
                  else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobData:blob:)])
                  {
                      [_delegate storageClient:self didFetchBlobData:data blob:blob];
                  }
              }];
         }];
    }
    else
    {
        NSString* endpoint = [NSString stringWithFormat:@"/%@/%@", blob.container.name, blob.name];
		request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob", nil];
        
        [request fetchDataWithCompletionHandler:^(WACloudURLRequest* request, NSData* data, NSError* error)
         {
             if(error)
             {
                 if(block)
                 {
                     block(nil, error);
                 }
                 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                 {
                     [_delegate storageClient:self didFailRequest:request withError:error];
                 }
                 return;
             }
             
             if(block)
             {
                 block(data, nil);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFetchBlobData:blob:)])
             {
                 [_delegate storageClient:self didFetchBlobData:data blob:blob];
             }
         }];
    }
}

- (void)addBlobToContainer:(WABlobContainer *)container blobName:(NSString *)blobName contentData:(NSData *)contentData contentType:(NSString*)contentType
{
    [self addBlobToContainer:container blobName:blobName contentData:contentData contentType:contentType withCompletionHandler:nil];
}

- (void)addBlobToContainer:(WABlobContainer *)container blobName:(NSString *)blobName contentData:(NSData *)contentData contentType:(NSString*)contentType withCompletionHandler:(void (^)(NSError*))block
{
    WACloudURLRequest* request;
    if(_credential.usesProxy)
    {
		request = [_credential authenticatedRequestWithEndpoint:@"/SharedAccessSignatureService/container" forStorageType:@"blob", nil];
        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
         {
			 if(error)
			 {
				 if(block)
				 {
					 block(error);
				 }
				 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
				 {
					 [_delegate storageClient:self didFailRequest:request withError:error];
				 }
				 return;
			 }
			    
             NSArray* containers = [WAContainerParser loadContainersForProxy:doc];
             WABlobContainer* theOnlyContainer = [containers objectAtIndex:0];
             NSString* endpoint = [NSString stringWithFormat:@"%@/%@?%@", theOnlyContainer.URL, [blobName URLEncode], theOnlyContainer.metadata];
             NSURL* serviceURL = [NSURL URLWithString:endpoint]; 
			 WACloudURLRequest* blobRequest = [WACloudURLRequest requestWithURL:serviceURL];
			 [blobRequest setHTTPMethod:@"PUT"];
			 [blobRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
			 [blobRequest addValue:@"BlockBlob" forHTTPHeaderField:@"x-ms-blob-type"];
			 [blobRequest setHTTPBody:contentData];

			 [blobRequest fetchNoResponseWithCompletionHandler:^(WACloudURLRequest* request, NSError* error)
              {
                  if(error)
                  {
                      if(block)
                      {
                          block(error);
                      }
                      else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                      {
                          [_delegate storageClient:self didFailRequest:request withError:error];
                      }
                      return;
                  }
                  
                  if(block)
                  {
                      block(nil);
                  }
                  else if([_delegate respondsToSelector:@selector(storageClient:didAddBlobToContainer:blobName:)])
                  {
                      [_delegate storageClient:self didAddBlobToContainer:container blobName:blobName];
                  }
              }];
         }];
	}
    else
    {
        NSString* containerName = [container.name lowercaseString];
        NSString*   endpoint = [NSString stringWithFormat:@"/%@/%@", [containerName URLEncode], [blobName URLEncode]]; 
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob" httpMethod:@"PUT" contentData:contentData contentType:contentType, @"x-ms-blob-type", @"BlockBlob", nil];
        
        [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest* request, NSError* error)
         {
             if(error)
             {
                 if(block)
                 {
                     block(error);
                 }
                 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                 {
                     [_delegate storageClient:self didFailRequest:request withError:error];
                 }
                 return;
             }
             
             if(block)
             {
                 block(nil);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didAddBlobToContainer:blobName:)])
             {
                 [_delegate storageClient:self didAddBlobToContainer:container blobName:blobName];
             }
         }];
    }
}

- (void)deleteBlob:(WABlob *)blob 
{
    [self deleteBlob:blob withCompletionHandler:nil];
}

- (void)deleteBlob:(WABlob *)blob withCompletionHandler:(void (^)(NSError*))block
{
    WACloudURLRequest* request;
    if (_credential.usesProxy) 
	{
        request = [_credential authenticatedRequestWithEndpoint:@"/SharedAccessSignatureService/container" forStorageType:@"blob", nil];

        [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
         {
             
             NSArray* containers = [WAContainerParser loadContainersForProxy:doc];
             WABlobContainer* theOnlyContainer = [containers objectAtIndex:0];
             NSString* endpoint = [NSString stringWithFormat:@"%@/%@?%@", theOnlyContainer.URL, [blob.name URLEncode], theOnlyContainer.metadata];
             NSURL* serviceURL = [NSURL URLWithString:endpoint]; 
             // WACloudURLRequest* blobRequest = [_credential authenticatedBlobRequestWithURL:serviceURL forStorageType:@"blob" httpMethod:@"DELETE" contentData:[NSData data] contentType:nil, nil];
			 
			 WACloudURLRequest* blobRequest = [WACloudURLRequest requestWithURL:serviceURL];
			 [blobRequest setHTTPMethod:@"DELETE"];
			 
             [blobRequest fetchNoResponseWithCompletionHandler:^(WACloudURLRequest* request, NSError* error)
              {
                  if(error)
                  {
                      if(block)
                      {
                          block(error);
                      }
                      else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                      {
                          [_delegate storageClient:self didFailRequest:request withError:error];
                      }
                      return;
                  }
                  
                  if(block)
                  {
                      block(nil);
                  }
                  else if([_delegate respondsToSelector:@selector(storageClient:didDeleteBlob:)])
                  {
                      [_delegate storageClient:self didDeleteBlob:blob];
                  }
              }];
         }];
    }
    else 
	{
        NSString* endpoint = [NSString stringWithFormat:@"/%@/%@", [blob.container.name URLEncode], [blob.name URLEncode]];
        request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"blob" httpMethod:@"DELETE" contentData:[NSData data] contentType:nil, nil];

        [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest* request, NSError* error)
         {
             if(error)
             {
                 if(block)
                 {
                     block(error);
                 }
                 else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
                 {
                     [_delegate storageClient:self didFailRequest:request withError:error];
                 }
                 return;
             }
             
             if(block)
             {
                 block(nil);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didDeleteBlob:)])
             {
                 [_delegate storageClient:self didDeleteBlob:blob];
             }
         }];
    }
}

#pragma mark -
#pragma mark Table API methods

- (void)fetchTables
{
    [self fetchTablesWithCompletionHandler:nil];
}

- (void)fetchTablesWithCompletionHandler:(void (^)(NSArray *, NSError *))block
{
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:@"Tables" forStorageType:@"table" httpMethod:@"GET", nil];
    [self prepareTableRequest:request];
    
    [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
     {
         if(error)
         {
             if(block)
             {
                 block(nil, error);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         NSMutableArray* tables = [NSMutableArray arrayWithCapacity:20];
         
         [WAXMLHelper parseAtomPub:doc block:^(WAAtomPubEntry* entry) 
         {
             [entry processContentPropertiesWithBlock:^(NSString * name, NSString * value) {
                 if([name isEqualToString:@"TableName"])
                 {
                     [tables addObject:value];
                 }
             }];
         }];
         
         if(block)
         {
             block(tables, nil);
         }
         else if([_delegate respondsToSelector:@selector(storageClient:didFetchTables:)])
         {
             [_delegate storageClient:self didFetchTables:tables];
         }
     }];
}

- (void)createTableNamed:(NSString *)newTableName
{
    [self createTableNamed:newTableName withCompletionHandler:nil];
}

- (void)createTableNamed:(NSString *)newTableName withCompletionHandler:(void (^)(NSError *))block
{
    NSString* requestDataString;
    NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
	NSString *dateString = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
    
    [dateFormatter release];
    
	requestDataString = [[CREATE_TABLE_REQUEST_STRING stringByReplacingOccurrencesOfString:@"$UPDATEDDATE$" withString:dateString] stringByReplacingOccurrencesOfString:@"$TABLENAME$" withString:newTableName];
    
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:@"Tables" 
                                                              forStorageType:@"table" 
                                                                  httpMethod:@"POST"
                                                                 contentData:[requestDataString dataUsingEncoding:NSUTF8StringEncoding]
                                                                 contentType:@"application/atom+xml", nil];    
    [self prepareTableRequest:request];

    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest* request, NSError* error)
     {
         if(error)
         {
             if(block)
             {
                 block(error);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }

		if (block)
		{
			block(nil);
		}
		else if ([(id)_delegate respondsToSelector:@selector(storageClient:didCreateTableNamed:)])
		{
			[_delegate storageClient:self didCreateTableNamed:newTableName];
		}
     }];
}

- (void)deleteTableNamed:(NSString *)tableName
{
    [self deleteTableNamed:tableName withCompletionHandler:nil];
}

- (void)deleteTableNamed:(NSString *)tableName withCompletionHandler:(void (^)(NSError *))block
{
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:[@"Tables" stringByAppendingFormat:@"(\'%@\')", tableName] forStorageType:@"table" httpMethod:@"DELETE", nil];
	[self prepareTableRequest:request];
	
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest* request, NSError* error)
     {
         if (error)
         {
             if (block)
             {
                 block (error);
             }
             else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if (block)
         {
             block (nil);
         }
         else if ([(id)_delegate respondsToSelector:@selector(storageClient:didDeleteTableNamed:)])
         {
             [_delegate storageClient:self didDeleteTableNamed:tableName];
         }
     }];
}

- (void)fetchEntities:(WATableFetchRequest*)fetchRequest
{
    [self fetchEntities:fetchRequest withCompletionHandler:nil];
}

- (void)fetchEntities:(WATableFetchRequest*)fetchRequest withCompletionHandler:(void (^)(NSArray*, NSError *))block
{
	NSString* endpoint = [fetchRequest endpoint];
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"table" httpMethod:@"GET", nil];
	
    [self prepareTableRequest:request];
    
	[request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError *error)
     {
         if (error)
         {
             if (block)
             {
                 block (nil, error);
             }
             else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         // NSArray *entities = [self parseEntities:doc];
         NSMutableArray* entities = [NSMutableArray arrayWithCapacity:50];
         [WAXMLHelper parseAtomPub:doc block:^(WAAtomPubEntry* entry) 
          {
              NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:10];
              
              [entry processContentPropertiesWithBlock:^(NSString * name, NSString * value) 
              {
                  [dict setObject:value forKey:name];
              }];
              
              WATableEntity* entity = [[WATableEntity alloc] initWithDictionary:dict fromTable:fetchRequest.tableName];
              [entities addObject:entity];
              [entity release];
          }];
         
         if (block)
         {
             block(entities, nil);
         }
         else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFetchEntities:fromTableNamed:)])
         {
             [_delegate storageClient:self didFetchEntities:entities fromTableNamed:fetchRequest.tableName];
         }
     }];
}

- (BOOL)insertEntity:(WATableEntity *)newEntity
{
    return [self insertEntity:newEntity withCompletionHandler:nil];
}

- (BOOL)insertEntity:(WATableEntity *)newEntity withCompletionHandler:(void (^)(NSError *))block
{
    NSString	*requestDataString = nil;
	NSString	*properties = [newEntity propertyString];
    
    if(!properties)
    {
		if (block)
		{
			block ([NSError errorWithDomain:@"CloudStorageClient" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]);
		}
		else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
		{
			[_delegate storageClient:self didFailRequest:nil withError:[NSError errorWithDomain:@"CloudStorageClient" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]];
		}
        return NO;
    }
    
	// Construct the date in the right format
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc]init] autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
	NSString *dateString = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
	
	requestDataString = [[TABLE_INSERT_ENTITY_REQUEST_STRING stringByReplacingOccurrencesOfString:@"$UPDATEDDATE$" withString:dateString] stringByReplacingOccurrencesOfString:@"$PROPERTIES$" withString:properties];
	
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:newEntity.tableName 
                                                              forStorageType:@"table" 
                                                                  httpMethod:@"POST" 
                                                                 contentData:[requestDataString dataUsingEncoding:NSASCIIStringEncoding] 
                                                                 contentType:@"application/atom+xml", nil];
    [self prepareTableRequest:request];
    
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest* request, NSError* error)
     {
         if (error)
         {
             if (block)
             {
                 block (error);
             }
             else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if (block)
         {
             block (nil);
         }
         else if ([(id)_delegate respondsToSelector:@selector(storageClient:didInsertEntity:)])
         {
             [_delegate storageClient:self didInsertEntity:newEntity];
         }
     }];
    
    return YES;
}

- (BOOL)updateEntity:(WATableEntity *)existingEntity
{
    return [self updateEntity:existingEntity withCompletionHandler:nil];
}

- (BOOL)updateEntity:(WATableEntity *)existingEntity withCompletionHandler:(void (^)(NSError *))block
{
	NSString* properties = [existingEntity propertyString];
    
    if(!properties)
    {
		if (block)
		{
			block ([NSError errorWithDomain:@"CloudStorageClient" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]);
		}
		else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
		{
			[_delegate storageClient:self didFailRequest:nil withError:[NSError errorWithDomain:@"CloudStorageClient" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]];
		}
		return NO;
    }

    NSString* requestDataString = nil;
	NSString* endpoint = [existingEntity endpoint];
	
    // Construct the date in the right format
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc]init] autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
	NSString *dateString = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
    
    NSURL* serviceURL = [_credential URLforEndpoint:endpoint forStorageType:@"table"];
    
	requestDataString = [[[TABLE_UPDATE_ENTITY_REQUEST_STRING stringByReplacingOccurrencesOfString:@"$UPDATEDDATE$" withString:dateString] stringByReplacingOccurrencesOfString:@"$PROPERTIES$" withString:properties] stringByReplacingOccurrencesOfString:@"$ENTITYID$" withString:[serviceURL absoluteString]];
	
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint 
                                                              forStorageType:@"table" 
                                                                  httpMethod:@"PUT"
                                                                 contentData:[requestDataString dataUsingEncoding:NSASCIIStringEncoding]
                                                                 contentType:@"application/atom+xml", nil];
    [self prepareTableRequest:request];
	[request setValue:@"*" forHTTPHeaderField:@"If-Match"];
	
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest* request, NSError* error)
     {
         if (error)
         {
             if (block)
             {
                 block (error);
             }
             else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if (block)
         {
             block (nil);
         }
         else if ([(id)_delegate respondsToSelector:@selector(storageClient:didUpdateEntity:)])
         {
             [_delegate storageClient:self didUpdateEntity:existingEntity];
         }
     }];
    
    return YES;
}

- (BOOL)mergeEntity:(WATableEntity *)existingEntity 
{
    return [self mergeEntity:existingEntity withCompletionHandler:nil];
}

- (BOOL)mergeEntity:(WATableEntity *)existingEntity withCompletionHandler:(void (^)(NSError *))block
{
	NSString* properties = [existingEntity propertyString];
    
    if(!properties)
    {
		if (block)
		{
			block ([NSError errorWithDomain:@"CloudStorageClient" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]);
		}
		else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
		{
			[_delegate storageClient:self didFailRequest:nil withError:[NSError errorWithDomain:@"CloudStorageClient" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Required properties not found in entity" forKey:NSLocalizedDescriptionKey]]];
		}
		return NO;
    }
    
    NSString* requestDataString = nil;
	NSString* endpoint = [existingEntity endpoint];

	// Construct the date in the right format
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
	NSString *dateString = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
	
    NSURL* serviceURL = [_credential URLforEndpoint:endpoint forStorageType:@"table"];
	requestDataString = [[[TABLE_UPDATE_ENTITY_REQUEST_STRING stringByReplacingOccurrencesOfString:@"$UPDATEDDATE$" withString:dateString] stringByReplacingOccurrencesOfString:@"$PROPERTIES$" withString:properties] stringByReplacingOccurrencesOfString:@"$ENTITYID$" withString:[serviceURL path]];
    
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint 
                                                              forStorageType:@"table" 
                                                                  httpMethod:@"MERGE"
                                                                 contentData:[requestDataString dataUsingEncoding:NSASCIIStringEncoding]
                                                                 contentType:@"application/atom+xml", nil];
    [self prepareTableRequest:request];
	[request setValue:@"*" forHTTPHeaderField:@"If-Match"];
	
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest* request, NSError* error)
     {
         if (error)
         {
             if (block)
             {
                 block (error);
             }
             else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if (block)
         {
             block (nil);
         }
         else if ([(id)_delegate respondsToSelector:@selector(storageClient:didMergeEntity:)])
         {
             [_delegate storageClient:self didMergeEntity:existingEntity];
         }
     }];
    
    return YES;
}

- (BOOL)deleteEntity:(WATableEntity *)existingEntity
{
    return [self deleteEntity:existingEntity withCompletionHandler:nil];
}

- (BOOL)deleteEntity:(WATableEntity *)existingEntity withCompletionHandler:(void (^)(NSError *))block
{
	NSString* endpoint = [existingEntity endpoint];
	
	if (!endpoint)
    {
		if (block)
		{
			block ([NSError errorWithDomain:@"CloudStorageClient" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"No endpoint defined" forKey:NSLocalizedDescriptionKey]]);
		}
		else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
		{
			[_delegate storageClient:self didFailRequest:nil withError:[NSError errorWithDomain:@"CloudStorageClient" code:-1 userInfo:[NSDictionary dictionaryWithObject:@"No endpoint defined" forKey:NSLocalizedDescriptionKey]]];
		}
		return NO;
    }
    
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint 
                                                              forStorageType:@"table" 
                                                                  httpMethod:@"DELETE", nil];
    [self prepareTableRequest:request];

	[request setValue:@"*" forHTTPHeaderField:@"If-Match"];
	
    [request fetchNoResponseWithCompletionHandler:^(WACloudURLRequest* request, NSError* error)
     {
         if (error)
         {
             if (block)
             {
                 block (error);
             }
             else if ([(id)_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         if (block)
         {
             block (nil);
         }
         else if ([(id)_delegate respondsToSelector:@selector(storageClient:didDeleteEntity:)])
         {
             [_delegate storageClient:self didDeleteEntity:existingEntity];
         }
     }];
    
    return YES;
}

#pragma mark -
#pragma mark Private methods

- (void)privateGetQueueMessages:(NSString *)queueName fetchCount:(NSInteger)fetchCount useBlockError:(BOOL)useBlockError peekOnly:(BOOL)peekOnly withBlock:(void (^)(NSArray *, NSError *))block
{
	if(fetchCount > 32)
	{
		// apply Azure queue fetch limit...
		fetchCount = 32;
	}
	
	queueName = [queueName lowercaseString];
    NSString* endpoint = [NSString stringWithFormat:@"/%@/messages?numofmessages=%d", [queueName URLEncode], fetchCount];
	if(peekOnly)
	{
		endpoint = [endpoint stringByAppendingString:@"&peekonly=true"];
	}
	else
	{
		// allow 60 seconds to turn around and delete the message
		endpoint = [endpoint stringByAppendingString:@"&visibilitytimeout=60"];
	}
	
    WACloudURLRequest* request = [_credential authenticatedRequestWithEndpoint:endpoint forStorageType:@"queue", nil];

    [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
     {
         if(error)
         {
             if(useBlockError)
             {
                 block(nil, error);
             }
             else if([_delegate respondsToSelector:@selector(storageClient:didFailRequest:withError:)])
             {
                 [_delegate storageClient:self didFailRequest:request withError:error];
             }
             return;
         }
         
         NSArray* queueMessages = [WAQueueMessageParser loadQueueMessages:doc];
		 block(queueMessages, nil);
     }];
}

- (void) dealloc 
{
    _delegate = nil;
    [_credential release];

    [super dealloc];
}

#pragma mark -

@end
