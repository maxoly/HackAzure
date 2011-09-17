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

#import "WACloudAccessControlHomeRealm.h"

@implementation WACloudAccessControlHomeRealm

- (id)initWithPairs:(NSDictionary*)pairs emailSuffixes:(NSArray*)emailSuffixes
{
    if((self = [super init]))
    {
        _pairs = [pairs retain];
        _emailSuffixes = emailSuffixes.count > 0 ? [emailSuffixes copy] : nil;
    }
    
    return self;
}

- (void)dealloc
{
    [_pairs release];
    [_emailSuffixes release];
    
    [super dealloc];
}

- (NSString*) name
{
    return [_pairs objectForKey:@"Name"];
}

- (NSString*) loginUrl
{
    return [_pairs objectForKey:@"LoginUrl"];
}

- (NSString*) logoutUrl
{
    return [_pairs objectForKey:@"LogoutUrl"];
}

- (NSString*) imageUrl
{
    return [_pairs objectForKey:@"ImageUrl"];
}

- (NSArray*) emailSuffixes
{
    return _emailSuffixes;
}

@end
