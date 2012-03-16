//
//  ChatViewController+Mutability.m
//  AcaniChat
//
//  Created by Juguang Xiao on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatViewController+Mutability.h"

#import "Message.h"


#define ClearConversationButtonIndex 0

@implementation ChatViewController (Mutability)

+ (NSDate*) sendDateInMessage:(Message *)message {
    //return [message valueForKey: @"sentDate"];
	return message.sentDate;
}

+ (void) setIsMine:(BOOL)isMine inMessage:(Message *)message {
    message.isMine = [NSNumber numberWithBool:isMine];
}
// Returns number of objects added to cellMap (1 or 2).
- (NSUInteger)addMessage:(Message *)message 
{
    // Show sentDates at most every 15 minutes.
    NSDate *currentSentDate = [[self class] sendDateInMessage: message]; //  message.sentDate;
    NSUInteger numberOfObjectsAdded = 1;
    NSUInteger prevIndex = [cellMap count] - 1;
    
    // Show sentDates at most every 15 minutes.
    
    if([cellMap count])
    {
        // BOOL prevIsMessage = [[cellMap objectAtIndex:prevIndex] isKindOfClass:[Message class]];
        BOOL prevIsMessage = ! [[cellMap objectAtIndex:prevIndex] isKindOfClass:[NSDate class]];
        
        if(prevIsMessage)
        {
            id temp = [cellMap objectAtIndex:prevIndex];
            NSDate * previousSentDate =[[self class] sendDateInMessage: temp]; //  temp.sentDate;
            // if there has been more than a 15 min gap between this and the previous message!
            if([currentSentDate timeIntervalSinceDate:previousSentDate] > SECONDS_BETWEEN_MESSAGES) 
            { 
                [cellMap addObject:currentSentDate];
                numberOfObjectsAdded = 2;
            }
        }
    }
    else
    {
        // there are NO messages, definitely add a timestamp!
        [cellMap addObject:currentSentDate];
        numberOfObjectsAdded = 2;
    }
    
    [cellMap addObject:message];
	
    return numberOfObjectsAdded;
}

// Returns number of objects removed from cellMap (1 or 2).
- (NSUInteger)removeMessageAtIndex:(NSUInteger)index {
    //    NSLog(@"Delete message from cellMap");
    
    // Remove message from cellMap.
	[self removeMessage:[cellMap objectAtIndex:index]];
    [cellMap removeObjectAtIndex:index];
    NSUInteger numberOfObjectsRemoved = 1;
    NSUInteger prevIndex = index - 1;
    NSUInteger cellMapCount = [cellMap count];
    
    BOOL isLastObject = index == cellMapCount;
    BOOL prevIsDate = [[cellMap objectAtIndex:prevIndex] isKindOfClass:[NSDate class]];
    
    if ((isLastObject && prevIsDate) ||
        (prevIsDate && [[cellMap objectAtIndex:index] isKindOfClass:[NSDate class]])) {
        [cellMap removeObjectAtIndex:prevIndex];
        numberOfObjectsRemoved = 2;
    }
    
    
    return numberOfObjectsRemoved;
}

- (void)clearAll {
    UIActionSheet *confirm = [[UIActionSheet alloc]
                              initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:NSLocalizedString(@"Clear Conversation", nil)
                              otherButtonTitles:nil];
	
	// use the same style as the nav bar
	confirm.actionSheetStyle = (UIActionSheetStyle)self.navigationController.navigationBar.barStyle;
    
    [confirm showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
    //    [confirm showInView:self.view];
    
}

- (void) removeMessage:(Message *)message {
	// Remove message from managed object context by index path.
    [managedObjectContext deleteObject:(Message *)message];
    NSError *error;
    if (![managedObjectContext save:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"Delete message error %@, %@", error, [error userInfo]);
    }

}

- (void) clearAllMessage {
	NSError *error;
    fetchedResultsController.delegate = nil;               // turn off delegate callbacks
    for (Message *message in [fetchedResultsController fetchedObjects]) {
        [managedObjectContext deleteObject:message];
    }
    if (![managedObjectContext save:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"Delete message error %@, %@", error, [error userInfo]);
    }
    fetchedResultsController.delegate = self;              // reconnect after mass delete
    if (![fetchedResultsController performFetch:&error]) { // resync controller
        // TODO: Handle the error appropriately.
        NSLog(@"fetchResults error %@, %@", error, [error userInfo]);
    }
    
}
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case ClearConversationButtonIndex: {
            [self clearAllMessage];
                        
            [cellMap removeAllObjects];
            [chatContent reloadData];
            
            [self setEditing:NO animated:NO];
            break;
		}
	}
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) { // disable slide to delete
		return UITableViewCellEditingStyleDelete;
        //        return 3; // used to work for check boxes
    }
    return UITableViewCellEditingStyleNone;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return  ! [[cellMap objectAtIndex:[indexPath row]] isKindOfClass:[NSDate class]];
    
    //return [[cellMap objectAtIndex:[indexPath row]] isKindOfClass:[Message class]];
    //    return [[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] == kMessageCell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSObject *object = [cellMap objectAtIndex:[indexPath row]];
        if ([object isKindOfClass:[NSDate class]]) {
            return;
        }
        
        //        NSLog(@"Delete %@", object);
        
        //[self removeMessage: object];
        [self removeMessageAtIndex: indexPath.row];
        
        [chatContent reloadData];
    }
}


@end
