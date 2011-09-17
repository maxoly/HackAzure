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

#import "WACloudURLRequest.h"
#import "WAXMLHelper.h"
#import <libxml/parser.h>

#define SELF_SIGNED_SSL 1 // indicates that the library supports self signed SSL certs

#if SELF_SIGNED_SSL
static NSString* proxyAddress = nil;
#endif

#if USE_QUEUE
static WACloudURLRequest* _head = nil;
static WACloudURLRequest* _tail = nil;
static NSLock* _lock;
#endif

@implementation WACloudURLRequest

void ignoreSSLErrorFor(NSString* host)
{
#if SELF_SIGNED_SSL
	[proxyAddress release];
	proxyAddress = [[NSString stringWithFormat:@"%@.cloudapp.net", host] copy];
#endif
}

#if USE_QUEUE
#pragma mark Request Queuing support

- (void) append:(WACloudURLRequest*)request
{
    _tail = _next = [request retain];
}

- (WACloudURLRequest*)next
{
    return _next;
}

- (void) startNext
{
    [_lock lock];
    @try
    {
        WACloudURLRequest* next = [_head next];
        [_head release];
        if(next)
        {
            _head = next;
            [NSURLConnection connectionWithRequest:_head delegate:_head];
        }
        else
        {
            _head = _tail = nil;
        }
    }
    @finally 
    {
        [_lock unlock];
    }
}

- (void) queueRequest
{
    if(!_lock)
    {
        _lock = [[NSLock alloc] init];
    }
    
    [_lock lock];
    @try
    {
        if(_tail)
        {
            [_tail append:self];
        }
        else
        {
            _head = _tail = [self retain];

            // if I'm the first in queue, start me right away
            [NSURLConnection connectionWithRequest:self delegate:self];
        }
    }
    @finally 
    {
        [_lock unlock];
    }
}

#pragma mark -
#endif

- (void) fetchNoResponseWithCompletionHandler:(WANoResponseHandler)block
{
    _noResponseBlock = [block copy];

	WA_BEGIN_LOGGING
		NSLog(@"Request URL: %@", [self URL]);
	WA_END_LOGGING
	
#if USE_QUEUE
    [self queueRequest];
#else
	[NSURLConnection connectionWithRequest:self delegate:self];
#endif
}

- (void) fetchXMLWithCompletionHandler:(WAFetchXMLHandler)block
{
    _xmlBlock = [block copy];
	
	WA_BEGIN_LOGGING
		NSLog(@"Request URL: %@", [self URL]);
	WA_END_LOGGING
	
#if USE_QUEUE
    [self queueRequest];
#else
	[NSURLConnection connectionWithRequest:self delegate:self];
#endif
}

- (void) fetchDataWithCompletionHandler:(WAFetchDataHandler)block
{
    _dataBlock = [block copy];
	
	WA_BEGIN_LOGGING
		NSLog(@"Request URL: %@", [self URL]);
	WA_END_LOGGING
	
#if USE_QUEUE
    [self queueRequest];
#else
	[NSURLConnection connectionWithRequest:self delegate:self];
#endif
}

- (void)dealloc
{
	[_noResponseBlock release]; 
	[_xmlBlock release]; 
	[_dataBlock release]; 
	[_data release]; 
	[_contentType release]; 
	
	[super dealloc];
}

- (void)sendDataResponse:(NSData*)data error:(NSError*)err 
{
    if(_dataBlock)
    {
        _dataBlock(self, data, err);
        return;
    }
}

- (void)sendDocumentResponse:(xmlDocPtr)doc error:(NSError*)err 
{
    if(_xmlBlock)
    {
        _xmlBlock(self, doc, err);
        return;
    }
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _expectedContentLength = [response expectedContentLength];
	_contentType = [[response MIMEType] copy];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(!_data)
	{
		_data = [data mutableCopy];
	}
	else 
	{
		[_data appendData:data];
	}
}

#ifdef SELF_SIGNED_SSL

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if (proxyAddress && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		if ([challenge.protectionSpace.host isEqualToString:proxyAddress])
		{
			NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
			[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
		}
	}
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}
#endif

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(_contentType && [_contentType compare:@"text/html" options:NSCaseInsensitiveSearch] == NSOrderedSame)
	{
		NSString* htmlStr = [[[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding] autorelease];
		NSError* regexError;
		NSError* contentError = nil;
		NSRegularExpression* unauthorized = [NSRegularExpression regularExpressionWithPattern:@"401 - Unauthorized: (.*)</h2>"
																					   options:0 
																						 error:&regexError];
		NSTextCheckingResult* result = [unauthorized firstMatchInString:htmlStr options:0 range:NSMakeRange(0, htmlStr.length)];
		int found = [result numberOfRanges];
		if(found == 2)
		{
			// need to convert this into an error...
			NSRange r = [result rangeAtIndex:1];
			NSString* msg = [htmlStr substringWithRange:r];
			
			contentError = [NSError errorWithDomain:@"CloudStorageClient" 
											   code:401 
										   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil]];
		}

		if(contentError)
		{
			[self connection:connection didFailWithError:contentError];
			return;
		}
	}
	
    if(_noResponseBlock)
    {
		WA_BEGIN_LOGGING_CUSTOM(WALoggingResponse)
        if(_data)
        {
			NSString* xmlStr = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
			NSLog(@"XML response: %@", xmlStr);
			[xmlStr release];
        }
		WA_END_LOGGING
		
        if(_data)
        {
            const char *baseURL = NULL;
            const char *encoding = NULL;
            
            xmlDocPtr doc = xmlReadMemory([_data bytes], (int)[_data length], baseURL, encoding, (XML_PARSE_NOCDATA | XML_PARSE_NOBLANKS)); 
            NSError* error = [WAXMLHelper checkForError:doc];
            xmlFreeDoc(doc);
            
            if(error)
            {
                _noResponseBlock(self, error);
#if USE_QUEUE
				[self startNext];
#endif
                return;
            }
        }
        
        _noResponseBlock(self, nil);
    }
	else if(_xmlBlock)
	{
        const char *baseURL = NULL;
        const char *encoding = NULL;

		WA_BEGIN_LOGGING_CUSTOM(WALoggingResponse)
			NSString* xmlStr = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
			NSLog(@"XML response: %@", xmlStr);
			[xmlStr release];
		WA_END_LOGGING
        
        xmlDocPtr doc = xmlReadMemory([_data bytes], (int)[_data length], baseURL, encoding, (XML_PARSE_NOCDATA | XML_PARSE_NOBLANKS)); 
        
        NSError* error = [WAXMLHelper checkForError:doc];

        if(error)
        {
            _xmlBlock(self, nil, error);
        }
        else
        {
            _xmlBlock(self, doc, nil);
        }
		
		xmlFreeDoc(doc);
	}
	else if(_dataBlock)
	{
        _dataBlock(self, _data, nil);
	}

#if USE_QUEUE
    [self startNext];
#endif
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if(_noResponseBlock)
    {
        _noResponseBlock(self, error);
    }
	else if(_xmlBlock)
	{
        _xmlBlock(self, nil, error);
    }
    else if(_dataBlock)
    {
        _dataBlock(self, nil, error);
    }

#if USE_QUEUE
    [self startNext];
#endif
}

#pragma mark -

@end


@implementation NSString (URLEncode)

- (NSString*) URLEncode
{
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR(":/?#[]@!$&’()* +,;="), kCFStringEncodingUTF8); 
	return [result autorelease]; 
}

- (NSString*) URLDecode
{
	NSString *result = (NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8); 
	[result autorelease]; 
	
	return [result stringByReplacingOccurrencesOfString:@"+" withString:@" "];
}

@end
