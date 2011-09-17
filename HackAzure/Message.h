//
//  Message.h
//  HackAzure
//
//  Created by Massimo Oliviero on 9/17/11.
//  Copyright (c) 2011 Superpartes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Message : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * from;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * messageid;

@end
