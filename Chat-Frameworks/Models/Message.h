//
//  Message.h
//  AcaniChat
//
//  Created by Krystof Celba on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSDate * sentDate;
@property (nonatomic, retain) NSNumber * isMine;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) Conversation *conversation;

@end
