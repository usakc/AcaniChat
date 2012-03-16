//
//  ChatViewController+Mutability.h
//  AcaniChat
//
//  Created by Juguang Xiao on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatViewController.h"
#import "Message.h"

@interface ChatViewController (Mutability)

- (NSUInteger)addMessage:(Message *)message;
- (NSUInteger)removeMessageAtIndex:(NSUInteger)index;
- (void)clearAll;

- (void) clearAllMessage; 


- (void) removeMessage: (Message *) message; 
@end
