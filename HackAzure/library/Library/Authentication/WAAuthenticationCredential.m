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

#import <stdarg.h>
#import "WAAuthenticationCredential.h"
#import "WAAuthenticationCredential+Private.h"
#import "WACloudAccessToken.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>	
#import "WASimpleBase64.h"
#import "WACloudURLRequest.h"
#import "WAXMLHelper.h"

static NSString* PROXY_LOGIN_REQUEST_STRING = @"<Login xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/Microsoft.Samples.WindowsPhoneCloud.StorageClient.Credentials\"><Password>{password}</Password><UserName>{username}</UserName></Login>";

const int AUTHENTICATION_DELAY = 2;

@implementation WAAuthenticationCredential

@synthesize usesProxy   = _usesProxy;
@synthesize proxyURL    = _proxyURL;
@synthesize token       = _token;
@synthesize accountName = _accountName;
@synthesize accessKey   = _accessKey;
@synthesize tableServiceURL = _tableServiceURL;
@synthesize blobServiceURL = _blobServiceURL;


- (id)initWithAzureServiceAccount:(NSString*)name accessKey:(NSString*)key
{	
	if ((self = [super init]) != nil)
	{
		_usesProxy = NO;
		_accountName = [name copy];
		_accessKey = [key copy];
	}
	
	return self;
}

- (id)initWithProxyURL:(NSURL *)service user:(NSString *)user password:(NSString *)password
{
	if ((self = [super init]) != nil)
	{
		_usesProxy = YES;
		_proxyURL = [service retain];
        _username = [user copy];
        _password = [password copy];
	}

	return self;
}

- (id)initWithProxyURL:(NSURL *)proxyService tablesService:(NSURL *)tablesService blobsService:(NSURL *)blobsService user:(NSString *)user password:(NSString *)password
{
	if ((self = [super init]) != nil)
	{
		_usesProxy = YES;
		_proxyURL = [proxyService retain];
		_tableServiceURL = [tablesService retain];
		_blobServiceURL = [blobsService retain];
        _username = [user copy];
        _password = [password copy];
	}
	
	return self;
}

- (id)initWithProxyURL:(NSURL *)proxyService accessToken:(WACloudAccessToken*)accessToken
{
	if ((self = [super init]) != nil)
	{
		_usesProxy = YES;
		_proxyURL = [proxyService retain];
		_accessToken = [accessToken retain];						
	}
	
	return self;
}

- (BOOL)authenticateWithCompletionHandler:(void (^)(NSError*))block error:(NSError **)returnError
{
    NSString *requestString = [[PROXY_LOGIN_REQUEST_STRING stringByReplacingOccurrencesOfString:@"{password}" withString:_password] stringByReplacingOccurrencesOfString:@"{username}" withString:_username];
    WACloudURLRequest *request = [WACloudURLRequest requestWithURL:[NSURL URLWithString:@"/AuthenticationService/login" relativeToURL:_proxyURL]];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	
	NSData* requestData = [requestString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestData];
    
    [request fetchXMLWithCompletionHandler:^(WACloudURLRequest* request, xmlDocPtr doc, NSError* error)
     {
         if(error)
         {
             if(block)
             {
                 block(error);
             }
             else
             {
                 _authError = [error retain];
             }
             return;
         }
         
         _token = [[WAXMLHelper getElementValue:(xmlNodePtr)doc name:@"string"] retain];
         
         if(block)
         {
             block(nil);
         }
     }];
	
	if(!block)
	{
		while(!_token && !_authError)
		{
			[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:AUTHENTICATION_DELAY]];
		}

		if (_authError && returnError)
		{
			*returnError = [_authError autorelease];
            return NO;
		}
	}
    
    return YES;
}

#pragma mark Creation methods

+ (WAAuthenticationCredential *)credentialWithAzureServiceAccount:(NSString*)accountName accessKey:(NSString*)accessKey
{
	return [[[self alloc] initWithAzureServiceAccount:accountName accessKey:accessKey] autorelease];
}

+ (WAAuthenticationCredential *)authenticateCredentialSynchronousWithProxyURL:(NSURL *)proxyURL user:(NSString *)user password:(NSString *)password error:(NSError **)returnError
{
	WAAuthenticationCredential* credential = [[[self alloc] initWithProxyURL:proxyURL user:user password:password] autorelease];
	
	return [credential authenticateWithCompletionHandler:nil error:returnError] ? credential : nil;
}

+ (WAAuthenticationCredential *)authenticateCredentialSynchronousWithProxyURL:(NSURL *)proxyURL tableServiceURL:(NSURL *)tablesURL blobServiceURL:(NSURL *)blobsURL user:(NSString *)user password:(NSString *)password error:(NSError **)returnError;
{
	WAAuthenticationCredential* credential = [[[self alloc] initWithProxyURL:proxyURL tablesService:(NSURL *)tablesURL blobsService:(NSURL *)blobsURL user:user password:password] autorelease];
	
	return [credential authenticateWithCompletionHandler:nil error:returnError] ? credential : nil;
}

+ (WAAuthenticationCredential *)authenticateCredentialWithProxyURL:(NSURL *)proxyURL user:(NSString *)user password:(NSString *)password delegate:(id<WAAuthenticationDelegate>)delegate
{
    return [self authenticateCredentialWithProxyURL:proxyURL user:user password:password withCompletionHandler:^(NSError* error)
            {
                if(error)
                {
                    [delegate loginDidFailWithError:error];
                }
                else
                {
                    [delegate loginDidSucceed];
                }
            }];
}

+ (WAAuthenticationCredential *)authenticateCredentialWithProxyURL:(NSURL *)proxyURL user:(NSString *)user password:(NSString *)password withCompletionHandler:(void (^)(NSError*))block
{
	WAAuthenticationCredential* credential = [[[self alloc] initWithProxyURL:proxyURL user:user password:password] autorelease];
	
	[credential authenticateWithCompletionHandler:block error:nil];

	return credential;
}

+ (WAAuthenticationCredential *)authenticateCredentialWithProxyURL:(NSURL *)proxyURL accessToken:(WACloudAccessToken*)accessToken
{
	return [[[self alloc] initWithProxyURL:proxyURL accessToken:accessToken] autorelease];
}

#pragma mark -
#pragma mark Request authentication methods

- (NSURL*)URLforEndpoint:(NSString *)endpoint forStorageType:(NSString *)storageType
{
	if (!endpoint || !storageType)
	{
		return (nil);
	}

    BOOL usingTableStorage = [[storageType lowercaseString] isEqualToString:@"table"];
    BOOL usingQueueStorage = [[storageType lowercaseString] isEqualToString:@"queue"];
    NSURL* serviceURL;
    
#if 1
    if (_usesProxy)
    {
        if (usingTableStorage)
		{
            endpoint = [NSString stringWithFormat:@"/AzureTablesProxy.axd/%@", endpoint];
            
            serviceURL = [[NSURL URLWithString:endpoint relativeToURL:_proxyURL] absoluteURL];
        }
        else if (usingQueueStorage)
        {
            endpoint = [NSString stringWithFormat:@"/AzureQueuesProxy.axd%@", endpoint];
            serviceURL = [[NSURL URLWithString:endpoint relativeToURL:_proxyURL] absoluteURL];
        }
        else
		{
            serviceURL = [[NSURL URLWithString:endpoint relativeToURL:_proxyURL] absoluteURL];
        }
    }
    else
    {
        NSString* cloudURL = [NSString stringWithFormat:@"http://%@.%@.core.windows.net/", _accountName, [storageType lowercaseString]];
        serviceURL = [[NSURL URLWithString:endpoint relativeToURL:[NSURL URLWithString:cloudURL]] absoluteURL];
    }
#else
	NSString				*servicePath = nil;
	if (_usesProxy)
	{
		if ([[storageType lowercaseString] isEqualToString:@"table"])
		{
			servicePath = [[_proxyURL absoluteString] stringByAppendingFormat:@"/AzureTablesProxy.axd/%@", endpoint];
		}
        else if (usingQueueStorage)
        {
            servicePath = [[_proxyURL absoluteString] stringByAppendingFormat:@"/AzureQueuesProxy.axd%@", endpoint];
        }
		else
		{
			servicePath = [[_proxyURL absoluteString] stringByAppendingFormat:@"/%@", endpoint];
		}
	}
	else
	{
		servicePath = [@"http://" stringByAppendingFormat:@"%@.%@.core.windows.net/%@", _accountName, [storageType lowercaseString], endpoint];
	}
	serviceURL = [NSURL URLWithString:servicePath];
#endif
    
    if(!serviceURL)
    {
        WA_BEGIN_LOGGING
            NSLog(@"Service URL could not be created for endpoint: %@", endpoint);
        WA_END_LOGGING
    }
    
    return serviceURL;
}

- (WACloudURLRequest *)authenticatedRequestWithURL:(NSURL *)serviceURL blobSemantics:(BOOL)blobSemantics queueSemantics:(BOOL)queueSemantics httpMethod:(NSString*)httpMethod contentData:(NSData *)contentData contentType:(NSString*)contentType args:(va_list)args
{
	if (!serviceURL)
	{
		return nil;
	}
    
    NSString* contentLength = contentData ? [NSString stringWithFormat:@"%d", contentData.length] : @"";
    
	WACloudURLRequest* authenticatedrequest = [WACloudURLRequest requestWithURL:serviceURL];
    [authenticatedrequest setHTTPMethod:httpMethod];
    
    if (_usesProxy)
	{
		[authenticatedrequest setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];

		if(_accessToken)
		{
			[_accessToken signRequest:authenticatedrequest];
		}
		else if(_token)
		{
			[authenticatedrequest setValue:_token forHTTPHeaderField:@"AuthToken"];
		}
		
        if(queueSemantics)
        {
			[authenticatedrequest addValue:@"2009-09-19" forHTTPHeaderField:@"x-ms-version"];
        }
		
		if(contentType)
		{
			[authenticatedrequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
		}
		
		if(contentData)
		{
			[authenticatedrequest setHTTPBody:contentData];
		}
		
		return authenticatedrequest;
	}

	NSString* endpoint = [[[serviceURL path] copy] autorelease];
	NSString* query = [serviceURL query];
	if(query && query.length > 0)
	{
		// for table storage, look for the comp= parameter
		NSArray* args = [query componentsSeparatedByString:@"&"];
		
		if(blobSemantics)
		{
			NSMutableString* q = [NSMutableString stringWithCapacity:100];
			
			for(NSString* arg in [args sortedArrayUsingSelector:@selector(compare:)])
			{
				[q appendString:@"\n"];
				[q appendString:[arg stringByReplacingOccurrencesOfString:@"=" withString:@":"]];
			}
			
			query = q;
		}
		else if(queueSemantics)
		{
			NSString *noQuery = @"numofmessages";
			NSString *noQuery2 = @"popreceipt";
			NSRange range = [query rangeOfString : noQuery];
			NSRange range2 = [query rangeOfString : noQuery2];
			if ((range.location == NSNotFound) && (range2.location == NSNotFound)) {
			   query = [@"?" stringByAppendingString:query];
			}
			else {
				query = nil;
			}
		}
		else
		{
			query = nil;
			
			for(NSString* arg in args)
			{
				if([arg hasPrefix:@"comp="])
				{
					arg = [arg stringByReplacingOccurrencesOfString:@"=" withString:@":"];
					query = [@"\n" stringByAppendingString:arg];
					break;
				}
			}
		}
	}
	
	// Construct the date in the right format
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss 'GMT'"];
	NSString *dateString = [dateFormatter stringFromDate:date];
	[dateFormatter release];
	
	NSMutableArray* headers = [NSMutableArray arrayWithCapacity:20];
	NSString* name;
	NSString* header;
	BOOL isName = YES;
	while((header = va_arg(args, NSString*)))
	{
		if(isName)
		{
			name = header;
		}
		else
		{
			[headers addObject:[NSString stringWithFormat:@"%@:%@", name, header]];
			[authenticatedrequest setValue:header forHTTPHeaderField:name];
		}
		isName = !isName;
	}
	[headers addObject:[NSString stringWithFormat:@"x-ms-date:%@", dateString]];
	if (!queueSemantics) 
	{
		[headers addObject:@"x-ms-version:2009-09-19"];
	}
	[headers sortUsingSelector:@selector(compare:)];
	
	NSString* headerString = [headers componentsJoinedByString:@"\n"];        
	NSMutableString *requestString;
	
	const NSData *cKey  = [_accessKey dataWithBase64DecodedString];
	
	if(blobSemantics)
	{
		requestString = [NSMutableString stringWithFormat:@"%@\n\n\n%@\n\n%@\n\n\n\n\n\n\n%@\n/%@/", 
						 httpMethod, contentLength, contentType ? contentType : @"", headerString, _accountName];
	}
	else if(queueSemantics)
	{
		if (contentType != nil && [contentType length] > 0) {
			requestString = [NSMutableString stringWithFormat:@"%@\n\n%@\n\n%@\n/%@/", 
							 httpMethod, contentType, headerString, _accountName];
		}
		else {
			requestString = [NSMutableString stringWithFormat:@"%@\n\n\n\n%@\n/%@/", 
							 httpMethod, headerString, _accountName];
		}
	}
	else
	{
		NSString *contentMD5;
		
		if(contentData)
		{
			void* buffer = malloc(CC_SHA256_DIGEST_LENGTH);
			CCHmac(kCCHmacAlgSHA256, [cKey bytes], [cKey length], [contentData bytes], [contentData length], buffer);
			NSData *encodedData = [NSData dataWithBytesNoCopy:buffer length:CC_SHA256_DIGEST_LENGTH freeWhenDone:NO];
			contentMD5 = [encodedData stringWithBase64EncodedData];
			free(buffer);
			
			[authenticatedrequest addValue:contentMD5 forHTTPHeaderField:@"content-md5"];
		}
		else
		{
			contentMD5 = @"";
		}
		
		requestString = [NSMutableString stringWithFormat:@"%@\n%@\n%@\n%@\n/%@/", 
						 httpMethod, contentMD5, contentType ? contentType : @"", dateString, _accountName];
	}
	
	if(endpoint.length > 1)
	{
		[requestString appendString:[endpoint substringFromIndex:1]];
	}             
	if(query)
	{
		[requestString appendString:query];
	}
	// Create the hash
	const NSData *cData = [requestString dataUsingEncoding:NSASCIIStringEncoding];
	
	void* buffer = malloc(CC_SHA256_DIGEST_LENGTH);
	CCHmac(kCCHmacAlgSHA256, [cKey bytes], [cKey length], [cData bytes], [cData length], buffer);
	
	NSData *encodedData = [NSData dataWithBytesNoCopy:buffer length:CC_SHA256_DIGEST_LENGTH freeWhenDone:YES];
	NSString *hash = [encodedData stringWithBase64EncodedData];
	
    WA_BEGIN_LOGGING
		NSLog(@"Request string: %@", requestString);
		NSLog(@"Request hash: %@", hash);
	WA_END_LOGGING

	
	// Append to the Authorization Header
	NSString *authHeader = [NSString stringWithFormat:@"SharedKey %@:%@", _accountName, hash];
	
	// Set the request headers
	[authenticatedrequest addValue:dateString forHTTPHeaderField:@"x-ms-date"];
	if(blobSemantics)
	{
		[authenticatedrequest addValue:@"2009-09-19" forHTTPHeaderField:@"x-ms-version"];
	}
	[authenticatedrequest addValue:authHeader forHTTPHeaderField:@"Authorization"];
	
	if(contentType)
	{
		[authenticatedrequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
	}
	
	if(contentData && [contentData length] > 0 )
	{
		[authenticatedrequest setHTTPBody:contentData];
	}

	return authenticatedrequest;
}

- (WACloudURLRequest *)authenticatedRequestWithURL:(NSURL *)serviceURL forStorageType:(NSString *)storageType, ...
{
    va_list arg;
    va_start(arg, storageType);
    
    BOOL blobSemantics = [[storageType lowercaseString] isEqualToString:@"blob"];
    BOOL queueSemantics = [[storageType lowercaseString] isEqualToString:@"queue"];

    WACloudURLRequest* request = [self authenticatedRequestWithURL:serviceURL 
													 blobSemantics:blobSemantics
													queueSemantics:queueSemantics
														httpMethod:@"GET" 
													   contentData:nil 
													   contentType:nil
															  args:arg];
    va_end(arg);
    
    return request;
}

- (WACloudURLRequest *)authenticatedRequestWithURL:(NSURL *)serviceURL forStorageType:(NSString *)storageType httpMethod:(NSString*)httpMethod, ...
{
    va_list arg;
    va_start(arg, httpMethod);
    
    BOOL blobSemantics = [[storageType lowercaseString] isEqualToString:@"blob"];
    BOOL queueSemantics = [[storageType lowercaseString] isEqualToString:@"queue"];

    WACloudURLRequest* request = [self authenticatedRequestWithURL:serviceURL 
													 blobSemantics:blobSemantics
													queueSemantics:queueSemantics
														httpMethod:httpMethod 
													   contentData:nil 
													   contentType:nil
															  args:arg];
    va_end(arg);
    
    return request;
}

- (WACloudURLRequest *)authenticatedRequestWithURL:(NSURL *)serviceURL forStorageType:(NSString *)storageType httpMethod:(NSString*)httpMethod contentData:(NSData *)contentData contentType:(NSString*)contentType, ...
{
    va_list arg;
    va_start(arg, contentType);

    BOOL blobSemantics = [[storageType lowercaseString] isEqualToString:@"blob"];
    BOOL queueSemantics = [[storageType lowercaseString] isEqualToString:@"queue"];
    
    WACloudURLRequest* request = [self authenticatedRequestWithURL:serviceURL 
													 blobSemantics:blobSemantics
													queueSemantics:queueSemantics
														httpMethod:httpMethod 
													   contentData:contentData 
													   contentType:contentType
															  args:arg];
    va_end(arg);
    
    return request;
}


- (WACloudURLRequest *)authenticatedRequestWithEndpoint:(NSString *)endpoint forStorageType:(NSString *)storageType, ...
{
    va_list arg;
    va_start(arg, storageType);
    
    BOOL blobSemantics = [[storageType lowercaseString] isEqualToString:@"blob"];
    BOOL queueSemantics = [[storageType lowercaseString] isEqualToString:@"queue"];
    NSURL* serviceURL = [self URLforEndpoint:endpoint forStorageType:storageType];
    
    WACloudURLRequest* request = [self authenticatedRequestWithURL:serviceURL 
                                                   blobSemantics:blobSemantics
                                                  queueSemantics:queueSemantics
                                                      httpMethod:@"GET" 
                                                     contentData:nil 
                                                     contentType:nil
                                                            args:arg];
    
    va_end(arg);
    
    return request;
}

- (WACloudURLRequest *)authenticatedRequestWithEndpoint:(NSString *)endpoint forStorageType:(NSString *)storageType httpMethod:(NSString*)httpMethod, ...
{
    va_list arg;
    va_start(arg, httpMethod);
    
    BOOL blobSemantics = [[storageType lowercaseString] isEqualToString:@"blob"];
    BOOL queueSemantics = [[storageType lowercaseString] isEqualToString:@"queue"];
    NSURL* serviceURL = [self URLforEndpoint:endpoint forStorageType:storageType];

    WACloudURLRequest* request = [self authenticatedRequestWithURL:serviceURL 
                                                   blobSemantics:blobSemantics
                                                  queueSemantics:queueSemantics
                                                      httpMethod:httpMethod 
                                                     contentData:nil 
                                                     contentType:nil
                                                            args:arg];
    
    va_end(arg);
    
    return request;
}

- (WACloudURLRequest *)authenticatedRequestWithEndpoint:(NSString *)endpoint forStorageType:(NSString *)storageType httpMethod:(NSString*)httpMethod contentData:(NSData *)contentData contentType:(NSString*)contentType, ...
{
    va_list arg;
    va_start(arg, contentType);
    
    BOOL blobSemantics = [[storageType lowercaseString] isEqualToString:@"blob"];
    BOOL queueSemantics = [[storageType lowercaseString] isEqualToString:@"queue"];
    NSURL* serviceURL = [self URLforEndpoint:endpoint forStorageType:storageType];

     WACloudURLRequest* request = [self authenticatedRequestWithURL:serviceURL 
                                                    blobSemantics:blobSemantics
                                                   queueSemantics:queueSemantics
                                                       httpMethod:httpMethod 
                                                      contentData:contentData 
                                                      contentType:contentType
                                                             args:arg];
    
    va_end(arg);
    
    return request;
}

- (WACloudURLRequest *)authenticatedBlobRequestWithURL:(NSURL *)serviceURL forStorageType:(NSString *)storageType httpMethod:(NSString*)httpMethod contentData:(NSData *)contentData contentType:(NSString*)contentType, ...
{
    
    va_list arg;
    va_start(arg, contentType);
    
    BOOL blobSemantics = [[storageType lowercaseString] isEqualToString:@"blob"];
    
    WACloudURLRequest* request = [self authenticatedRequestWithURL:serviceURL 
													 blobSemantics:blobSemantics
													queueSemantics:NO
														httpMethod:httpMethod 
													   contentData:contentData 
													   contentType:contentType
															  args:arg];
    va_end(arg);
    
    return request;
}

#pragma mark -

- (void)dealloc
{
	[_proxyURL release];
	[_token release];
	[_accountName release];
	[_accessKey release];
	[_username release];
	[_password release];
	[_blobServiceURL release];
	[_tableServiceURL release];
	[_accessToken release];
	
	[super dealloc];
}

@end
