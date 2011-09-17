//
//  AddressBookManager.h
//  HackAzure
//
//  Created by Marco Gasparetto on 17/09/11.
//  Copyright 2011 App3. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDefaultsUserNumber @"DefaultsUserNumber"


@interface AddressBookManager : NSObject {
    
@private
    NSMutableDictionary *_contacts;
    NSString *_userNumber;
}

- (void)reload;
- (NSDictionary *)contacts;

- (void)setUserNumber:(NSString *)userNumber;
- (NSString *)userNumber;

@end
