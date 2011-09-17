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

#import "WABlobParser.h"
#import "WABlob.h"
#import "WAXMLHelper.h"

@interface WABlob (Private)

- (id)initBlobWithName:(NSString *)name URL:(NSString *)URL container:(WABlobContainer*)container;
- (id)initBlobWithName:(NSString *)name URL:(NSString *)URL;

@end

@implementation WABlobParser

+ (NSArray *)loadBlobs:(xmlDocPtr)doc container:(WABlobContainer*)container
{
    if (doc == nil) 
    { 
		return nil; 
	}
    
	NSMutableArray *blobs = [NSMutableArray arrayWithCapacity:30];
    
    [WAXMLHelper performXPath:@"/EnumerationResults/Blobs/Blob" 
                 onDocument:doc 
                      block:^(xmlNodePtr node)
     {
         NSString *name = [WAXMLHelper getElementValue:node name:@"Name"];
         NSString *url = [WAXMLHelper getElementValue:node name:@"Url"];
       
         WABlob *blob = [[WABlob alloc] initBlobWithName:name URL:url container:container];
         [blobs addObject:blob];
         [blob release];
     }];
	
	return [[blobs copy] autorelease];
}

+ (NSArray *)loadBlobsForProxy:(xmlDocPtr)doc container:(WABlobContainer*)container
{
    if (doc == nil) 
    { 
		return nil; 
	}
    
	NSMutableArray *blobs = [NSMutableArray arrayWithCapacity:30];
    
    [WAXMLHelper performXPath:@"/*/*/*" 
                 onDocument:doc 
                      block:^(xmlNodePtr node)
     {
         NSString *name = [WAXMLHelper getElementValue:node name:@"Name"];
         NSString *url = [WAXMLHelper getElementValue:node name:@"Url"];
         
         WABlob *blob = [[WABlob alloc] initBlobWithName:name URL:url container:container];
         [blobs addObject:blob];
         [blob release];
     }];
	
	return [[blobs copy] autorelease];
}

+ (NSArray *)loadBlobsForProxy:(xmlDocPtr)doc
{
    if (doc == nil) 
    { 
		return nil; 
	}
    
	NSMutableArray *blobs = [NSMutableArray arrayWithCapacity:30];
    
    [WAXMLHelper performXPath:@"/*/*/*" 
                   onDocument:doc 
                        block:^(xmlNodePtr node)
     {
         NSString *name = [WAXMLHelper getElementValue:node name:@"Name"];
         NSString *url = [WAXMLHelper getElementValue:node name:@"Url"];
         
         WABlob *blob = [[WABlob alloc] initBlobWithName:name URL:url];
         [blobs addObject:blob];
         [blob release];
     }];
	
	return [[blobs copy] autorelease];
}

@end
