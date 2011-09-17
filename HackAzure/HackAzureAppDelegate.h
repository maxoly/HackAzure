//
//  HackAzureAppDelegate.h
//  HackAzure
//
//  Created by Marco Gasparetto on 17/09/11.
//  Copyright 2011 App3. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAAuthenticationCredential.h"
#import "WAConfiguration.h"

@interface HackAzureAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate>
{
    WAAuthenticationCredential *authenticationCredential;
}

@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) WAAuthenticationCredential *authenticationCredential;

@end
