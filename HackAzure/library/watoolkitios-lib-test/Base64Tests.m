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

#import "Base64Tests.h"
#import "WASimpleBase64.h"

@implementation Base64Tests

- (void)testShouldEncodeStringProperly
{
    NSString *key = @"wlQ7pyhrrDexICQ+vXAPDJ+9UojvI9Yz3DCZdnWCcN4VHnNwgEUSeOGPksHMR59POgCtvz2T3iJQ95vGcPH49g==";
    
    NSData *data = [key dataWithBase64DecodedString];
    
    NSString *retKey = [data stringWithBase64EncodedData];
    
    
    STAssertEqualObjects(key, retKey, @"Encoded and Decoded key should be the same.");
}

@end
