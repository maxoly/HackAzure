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

#import "WACloudAccessControlClient.h"
#import "WALoginProgressViewController.h"
#import "NSString+URLEncode.h"

static WACloudAccessToken* _token = nil;

@implementation WACloudAccessControlClient

@synthesize realm = _realm;
@synthesize serviceNamespace = _serviceNamespace;

- (id)initForNamespace:(NSString*)serviceNamespace realm:(NSString*)realm
{
    if((self = [super init]))
    {
        _serviceNamespace = [serviceNamespace copy];
        _realm = [realm copy];
        
        NSString* url = [NSString stringWithFormat:@"https://%@.accesscontrol.windows.net/v2/metadata/IdentityProviders.js?protocol=javascriptnotify&realm=%@&version=1.0",
                         _serviceNamespace,
                         [_realm URLEncode]];
        _serviceURL = [[NSURL URLWithString:url] retain];
    }
    
    return self;
}

- (void)dealloc
{
    [_serviceNamespace release];
    [_realm release];
    [_serviceURL release];
    
    [super dealloc];
}

+ (WACloudAccessToken*)sharedToken
{
	return _token;
}

+ (void)logOut
{
	[_token release];
	_token = nil;
}

+ (WACloudAccessControlClient*)accessControlClientForNamespace:(NSString*)serviceNamespace realm:(NSString*)realm
{
    return [[[WACloudAccessControlClient alloc] initForNamespace:serviceNamespace realm:realm] autorelease];
}

- (UIViewController*)createViewControllerAllowsClose:(BOOL)allowsClose withCompletionHandler:(void (^)(BOOL authenticated))block
{
    UIViewController* progressController;
    
    progressController = [[WALoginProgressViewController alloc] initWithURL:_serviceURL 
																allowsClose:allowsClose
													  withCompletionHandler:^(WACloudAccessToken *token) 
						  {
							  if(token)
							  {
								  [_token release];
								  _token = [token retain];
							  }
							  
							  block(!!token);
						  }];

	return [progressController autorelease];
}

- (void)showInViewController:(UIViewController*)controller allowsClose:(BOOL)allowsClose withCompletionHandler:(void (^)(BOOL authenticated))block
{
    UIViewController* progressController = [self createViewControllerAllowsClose:allowsClose withCompletionHandler:block];
    
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:progressController];
    navController.navigationBar.barStyle = UIBarStyleBlack;
    
    [controller presentModalViewController:navController animated:YES];
    [navController release];
}

@end
