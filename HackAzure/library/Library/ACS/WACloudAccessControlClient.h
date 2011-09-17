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
#import <UIKit/UIKit.h>
#import "WACloudAccessToken.h"

/*! The cloud access client is used to authenticate against the Windows Azure Access Control Service (ACS). */
@interface WACloudAccessControlClient : NSObject 
{
    NSURL* _serviceURL;
    NSString* _realm;
    NSString* _serviceNamespace;
}

/*! Returns the realm the client was initialized with. */
@property (readonly) NSString* realm;
/*! Returns the service namespace the client was initialized with. */
@property (readonly) NSString* serviceNamespace;

/*! Create an access control client initialized with the given service namespace and realm. */
+ (WACloudAccessControlClient*)accessControlClientForNamespace:(NSString*)serviceNamespace realm:(NSString*)realm;

/*! Present the authentication user interface. The completion handler is called when the process is completed. */
- (UIViewController*)createViewControllerAllowsClose:(BOOL)allowsClose withCompletionHandler:(void (^)(BOOL authenticated))block;

/*! Present the authentication user interface. The completion handler is called when the process is completed. */
- (void)showInViewController:(UIViewController*)controller allowsClose:(BOOL)allowsClose withCompletionHandler:(void (^)(BOOL authenticated))block;

/*! Returns the security token that was set when the user authenticated through a call to requestAccessInViewController:withCompletionHandler:. */
+ (WACloudAccessToken*)sharedToken;

/*! Instructs the client to release the shared token. */
+ (void)logOut;

@end
