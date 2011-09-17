//
//  AddressBookManager.h
//  HackAzure
//
//  Created by Marco Gasparetto on 17/09/11.
//  Copyright 2011 App3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderedDictionary.h"

#define kDefaultsUserNumber @"DefaultsUserNumber"


@interface AddressBookManager : NSObject {
    
@private
    OrderedDictionary *_contacts;
    NSString *_userNumber;
}

- (void)reload;
- (OrderedDictionary *)contacts;

- (void)setUserNumber:(NSString *)userNumber;
- (NSString *)userNumber;

@end
