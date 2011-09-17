//
//  AddressBookManager.m
//  HackAzure
//
//  Created by Marco Gasparetto on 17/09/11.
//  Copyright 2011 App3. All rights reserved.
//

#import "AddressBookManager.h"
#import <AddressBook/AddressBook.h>

@implementation AddressBookManager

- (id)init
{
    self = [super init];
    if (self) {
        
        _contacts = [[OrderedDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [_contacts release];
    
    [super dealloc];
}

- (NSString *)parsePhoneNumber:(NSString *)phoneNumber
{
    NSString *result = [NSString stringWithString:phoneNumber];
    result = [result stringByReplacingOccurrencesOfString:@"+39" withString:@""];
    result = [result stringByReplacingOccurrencesOfString:@"(" withString:@""];
    result = [result stringByReplacingOccurrencesOfString:@")" withString:@""];
    result = [result stringByReplacingOccurrencesOfString:@"-" withString:@""];
    result = [result stringByReplacingOccurrencesOfString:@" " withString:@""];
    return result;
}

- (OrderedDictionary *)sortContacts:(OrderedDictionary *)contacts
{
    OrderedDictionary *result = [[OrderedDictionary alloc] init];
    NSArray *sortedKeys = [_contacts keysSortedByValueUsingSelector:@selector(compare:)];
    for (NSString *key in sortedKeys) {
        [result setObject:[_contacts valueForKey:key] forKey:key];
    }
    return [result autorelease];
}

- (void)reload
{
    [_contacts removeAllObjects];
    
    ABAddressBookRef addressBook = ABAddressBookCreate();
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    if (allPeople == nil) {
        CFRelease(addressBook);
        return;
    }

    CFIndex personCount = ABAddressBookGetPersonCount(addressBook);
    
    for (CFIndex i = 0; i < personCount; ++i) {
        
        ABRecordRef recordRef = CFArrayGetValueAtIndex(allPeople, i);
        
        NSString *firstName = nil;
        CFTypeRef firstNameRef = ABRecordCopyValue(recordRef, kABPersonFirstNameProperty);
        if (firstNameRef != nil) {
            firstName = [NSString stringWithString:(NSString *) firstNameRef];
            CFRelease(firstNameRef);
        }
        
        NSString *lastName = nil;
        CFTypeRef lastNameRef = ABRecordCopyValue(recordRef, kABPersonLastNameProperty);
        if (lastNameRef != nil) {
            lastName = [NSString stringWithString:(NSString *) lastNameRef];
            CFRelease(lastNameRef);
        }

        NSString *name = nil;
        if (firstName != nil && lastName == nil) {
            name = [NSString stringWithFormat:@"%@", lastName];
        } else if (firstName == nil && lastName != nil) {
            name = [NSString stringWithFormat:@"%@", lastName];
        } else if (firstName != nil && lastName != nil) {
            name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        } else {
            continue;
        }
        
        ABMultiValueRef allPhones = ABRecordCopyValue(recordRef, kABPersonPhoneProperty);
        if (allPhones == nil) {
            continue;
        }
        
        CFIndex phoneCount = ABMultiValueGetCount(allPhones);
        
        for (CFIndex j = 0; j < phoneCount; ++j)
        {
            NSString *phoneLocalizedLabel = nil;
            CFStringRef phoneLabelRef = ABMultiValueCopyLabelAtIndex(allPhones, j);
            if (phoneLabelRef != nil) {
                CFStringRef phoneLocalizedLabelRef = ABAddressBookCopyLocalizedLabel(phoneLabelRef);
                if (phoneLocalizedLabelRef != nil) {
                    phoneLocalizedLabel = [NSString stringWithString:(NSString *) phoneLocalizedLabelRef];
                    CFRelease(phoneLocalizedLabelRef);
                }
                CFRelease(phoneLabelRef);
            }
            
            NSString *phoneNumber = nil;;
            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(allPhones, j);
            if (phoneNumberRef != nil) {
                phoneNumber = [NSString stringWithString:(NSString *) phoneNumberRef];
                CFRelease(phoneNumberRef);
            }

            if (phoneLocalizedLabel != nil && phoneNumber != nil) {
                phoneNumber = [self parsePhoneNumber:phoneNumber];
                if ([phoneLocalizedLabel isEqualToString:@"iPhone"]) {
                    // NSLog(@"%@ - %@ (%@)", name, phoneNumber, phoneLocalizedLabel);
                    [_contacts setValue:name forKey:phoneNumber];
                }
            }
        }
        
        CFRelease(allPhones);
    }
    
    CFRelease(allPeople);
    CFRelease(addressBook);
    
    OrderedDictionary *sortedContacts = [self sortContacts:_contacts];
    [_contacts release];
    _contacts = sortedContacts;
    [_contacts retain];
}

- (OrderedDictionary *)contacts
{
    return [OrderedDictionary dictionaryWithDictionary:_contacts];
}

- (void)setUserNumber:(NSString *)userNumber
{
    [[NSUserDefaults standardUserDefaults] setValue:userNumber forKey:kDefaultsUserNumber];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)userNumber
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kDefaultsUserNumber];
}

@end
