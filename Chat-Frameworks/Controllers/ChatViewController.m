// Old
#import "ChatViewController.h"

#import "NSString+Additions.h"


#import "TVCell_Date.h"
#import "TVCell_Message.h"

#import "ChatViewController+Mutability.h"
#import "ChatViewController+Keyboard.h"



#define VIEW_WIDTH    self.view.frame.size.width
#define VIEW_HEIGHT    self.view.frame.size.height

#define RESET_CHAT_BAR_HEIGHT    SET_CHAT_BAR_HEIGHT(kChatBarHeight1)
#define EXPAND_CHAT_BAR_HEIGHT    SET_CHAT_BAR_HEIGHT(kChatBarHeight4)
#define SET_CHAT_BAR_HEIGHT(HEIGHT)\
CGRect chatContentFrame = chatContent.frame;\
chatContentFrame.size.height = VIEW_HEIGHT - HEIGHT;\
[UIView beginAnimations:nil context:NULL];\
[UIView setAnimationDuration:0.1f];\
chatContent.frame = chatContentFrame;\
chatBar.frame = CGRectMake(chatBar.frame.origin.x, chatContentFrame.size.height + toViewHeight,\
VIEW_WIDTH, HEIGHT);\
[UIView commitAnimations]



@implementation ChatViewController

@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize conversation;


+ (NSArray *) sortDescriptors {
    NSSortDescriptor *tsDesc = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:tsDesc, nil];
    return sortDescriptors;
}

+ (Class) delimiterClass {
    return [NSDate class];
}

+ (Class) contentClass {
    return  nil; // can be NSDict or Model_..
}
#pragma mark NSObject

- (void)dealloc {
    if (receiveMessageSound) AudioServicesDisposeSystemSoundID(receiveMessageSound);
}

#pragma mark UIViewController

- (void)viewDidUnload {
/*    self.chatContent = nil;
    self.chatBar = nil;

//    self.cellMap = nil;
    
  */  

    // Leave managedObjectContext since it's not recreated in viewDidLoad
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

#pragma mark NSFetchedResultsController

- (Conversation *) getConversationWithTitle:(NSString *)title
{
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = 
    [NSEntityDescription entityForName:@"Conversation"
                inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
    // Create the sort descriptors array.
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:NO]]];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"title == %@", title]];
	NSFetchedResultsController *fetchResult = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																				  managedObjectContext:managedObjectContext
														sectionNameKeyPath:nil cacheName:nil];
	
	NSError *error;
    if (![fetchResult performFetch:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"fetchResults error %@, %@", error, [error userInfo]);
		return  nil;
    }
	
	NSArray *fetchArray = [fetchResult fetchedObjects];
	NSLog(@"convers: %@", fetchArray);
	if ([fetchArray count] > 0) {
		return [fetchArray objectAtIndex:0];
	}
	else
	{
		return nil;
	}
	
}

- (void)fetchResults {
    if (fetchedResultsController) return;
    
    // Create and configure a fetch request.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = 
    [NSEntityDescription entityForName:@"Message"
                inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
    // Create the sort descriptors array.
	self.title = conversation.title;
    
    [fetchRequest setSortDescriptors:[[self class]sortDescriptors]];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"ANY conversation.title == %@", conversation.title]];
    
    // Create and initialize the fetchedResultsController
    fetchedResultsController = 
    [[NSFetchedResultsController alloc]
     initWithFetchRequest:fetchRequest
     managedObjectContext:managedObjectContext
     sectionNameKeyPath:nil /* one section */ cacheName:nil];
    
    fetchedResultsController.delegate = self;
    
    NSError *error;
    if (![fetchedResultsController performFetch:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"fetchResults error %@, %@", error, [error userInfo]);
    }
}  

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");

//    self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    
    // Listen for keyboard.
    [self registerKeyboard];

    self.view.backgroundColor = CHAT_BACKGROUND_COLOR; // shown during rotation
    
	toViewHeight = 0.0f;
	if (!conversation) 
	{
		toViewHeight = 40.0f;
		toView = [[ToView alloc] initWithFrame:CGRectMake(0.0f, 0.0f,
														  self.view.frame.size.width, toViewHeight)];
		[self.view addSubview:toView];
		[self.view sendSubviewToBack:toView];
	}
    
    // Create chatContent.
    chatContent = [[UITableView alloc] initWithFrame:
                   CGRectMake(0.0f, 0.0f + toViewHeight, self.view.frame.size.width,
                              self.view.frame.size.height-kChatBarHeight1-toViewHeight)];
    chatContent.clearsContextBeforeDrawing = NO;
    chatContent.delegate = self;
    chatContent.dataSource = self;
    chatContent.contentInset = UIEdgeInsetsMake(7.0f, 0.0f, 0.0f, 0.0f);
    chatContent.backgroundColor = CHAT_BACKGROUND_COLOR;
    chatContent.separatorStyle = UITableViewCellSeparatorStyleNone;
    chatContent.autoresizingMask = UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:chatContent];
    
    // Create chatBar.
    chatBar = [[ChatBar alloc] initWithFrame:
               CGRectMake(0.0f, self.view.frame.size.height-kChatBarHeight1,
                          self.view.frame.size.width, kChatBarHeight1)];

    chatBar.delegate= self;
    
    [self.view addSubview:chatBar];
    [self.view sendSubviewToBack:chatBar];
    
    
    if (conversation.title) 
	{
		[self fetchResults];
		// Construct cellMap from fetchedObjects.
		cellMap = [[NSMutableArray alloc]
				   initWithCapacity:[[fetchedResultsController fetchedObjects] count]*2];
		for (Message *message in [fetchedResultsController fetchedObjects]) {
			[self addMessage:message];
		}
	}

    
    // TODO: Implement check-box edit mode like iPhone Messages does. (Icebox)
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated]; // below: work around for [chatContent flashScrollIndicators]
    NSLog(@"viewWillAppear");
    [chatContent performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0.0];
    [self scrollToBottomAnimated:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
   // [chatBar.chatInput resignFirstResponder];
    [chatBar resignFirstResponder];
    
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    //return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    return YES; // yes to all. 
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:(BOOL)editing animated:(BOOL)animated];
    [chatContent setEditing:(BOOL)editing animated:(BOOL)animated]; // forward method call
//    chatContent.separatorStyle = editing ?
//            UITableViewCellSeparatorStyleSingleLine : UITableViewCellSeparatorStyleNone;
    
    if (editing) {
        UIBarButtonItem *clearAllButton =
        [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Clear All", nil) style:(UIBarButtonItemStylePlain) target: self action: @selector(clearAll)];
        
        //BAR_BUTTON(NSLocalizedString(@"Clear All", nil),
          //                                           @selector(clearAll));
        self.navigationItem.leftBarButtonItem = clearAllButton;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
    
//    if ([chatInput isFirstResponder]) {
//        NSLog(@"resign first responder");
//        [chatInput resignFirstResponder];
//    }
}

- (id) createNewMessageWithText: (NSString*) text
{
	if (!conversation) 
	{
		conversation = [self getConversationWithTitle:toView.toInput.text];
		if (!conversation) 
		{
			conversation = (Conversation *)[NSEntityDescription
											insertNewObjectForEntityForName:@"Conversation"
											inManagedObjectContext:managedObjectContext];
		}
		[self fetchResults];
		// Construct cellMap from fetchedObjects.
		cellMap = [[NSMutableArray alloc]
				   initWithCapacity:[[fetchedResultsController fetchedObjects] count]*2];
		for (Message *message in [fetchedResultsController fetchedObjects]) {
			[self addMessage:message];
		}
		conversation.title = toView.toInput.text;
		//remove toView
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.1f];
		[toView removeFromSuperview];
		toViewHeight = 0;
		chatContent.frame = CGRectMake(0.0f, 0.0f + toViewHeight, self.view.frame.size.width,
									   self.view.frame.size.height-kChatBarHeight1-toViewHeight);
		[UIView commitAnimations];
		toView = nil;
	}
    // Create new message
    Message *newMessage = (Message *)
    [NSEntityDescription
     insertNewObjectForEntityForName:@"Message"
     inManagedObjectContext:managedObjectContext];
    newMessage.text = text;
    NSDate *now = [[NSDate alloc] init]; 
    newMessage.sentDate = now; 
	
	BOOL isMine_ = (([cellMap count] %3) == 0);
    //[[self class] setIsMine: isMine_ inMessage: message];
    newMessage.isMine = [NSNumber numberWithBool: isMine_];
	newMessage.conversation = self.conversation;
	[self.conversation addMessagesObject:newMessage];
	[self.conversation setLastMessage:newMessage];
	
	NSLog(@"Save new message");
	NSError *error;
	if (![managedObjectContext save:&error]) {
		// TODO: Handle the error appropriately.
		NSLog(@"Save message error %@, %@", error, [error userInfo]);
	}
	
    return newMessage;
}

#pragma mark Message
- (void) chatBar:(ChatBar *)_chatBar didSendText:(NSString *)text {
    
//    // TODO: Show progress indicator like iPhone Message app does. (Icebox)
//    [activityIndicator startAnimating];
    
    NSString *rightTrimmedMessage = [text stringByTrimmingTrailingWhitespaceAndNewlineCharacters];
    
    // Don't send blank messages.
    if (rightTrimmedMessage.length == 0) {
        [_chatBar clearChatInput];
        return;
    }
    
    Message *message = [self createNewMessageWithText:text];

	[self addMessage:message];
	[chatContent reloadData];
   
    
    [chatBar clearChatInput]; // ????????
    
    [self scrollToBottomAnimated:YES]; // must come after RESET_CHAT_BAR_HEIGHT above
    
    // Play sound or buzz, depending on user settings.
    NSString *sendPath = [[NSBundle mainBundle] pathForResource:@"basicsound" ofType:@"wav"];
    CFURLRef baseURL = (__bridge CFURLRef)[NSURL fileURLWithPath:sendPath];
    AudioServicesCreateSystemSoundID(baseURL, &receiveMessageSound);
    AudioServicesPlaySystemSound(receiveMessageSound);
//    AudioServicesPlayAlertSound(receiveMessageSound); // use for receiveMessage (sound & vibrate)
//    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // explicit vibrate
}


#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"number of rows: %d", [cellMap count]);
    return [cellMap count];
}

static NSString *kMessageCell = @"MessageCell";

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    NSLog(@"cell for row: %d", [indexPath row]);
    
    NSObject *object = [cellMap objectAtIndex:[indexPath row]];
    
    // Handle sentDate (NSDate).
    if ([object isKindOfClass:[NSDate class]]) {
        static NSString *kSentDateCellId = @"SentDateCell";
        TVCell_Date * cell_date = nil;
        cell_date = [tableView dequeueReusableCellWithIdentifier:kSentDateCellId];
        if (cell_date == nil) {
            
            cell_date = [[TVCell_Date alloc] initWithReuseIdentifier: kSentDateCellId];
        }
        
        cell_date.date = (NSDate *)object;
        
        return cell_date;
    }
	else if ([object isKindOfClass:[Message class]]) {
        // Mark message as read.
        // Let's instead do this (asynchronously) from loadView and iterate over all messages
        if (![(Message *)object read]) { // not read, so save as read
            [(Message *)object setRead:[NSNumber numberWithBool:YES]];
			NSLog(@"Save as read");
            NSError *error;
            if (![managedObjectContext save:&error]) {
                // TODO: Handle the error appropriately.
                NSLog(@"Save message as read error %@, %@", error, [error userInfo]);
            }
        }
		// Handle Message object.
		TVCell_Message * cell_message;
		cell_message = [tableView dequeueReusableCellWithIdentifier:kMessageCell];
		if (cell_message == nil) {
			cell_message = [[TVCell_Message alloc] initWithReuseIdentifier: kMessageCell];
		}
		//[cell_message setMessage: (Message *)object rightward: !([indexPath row] % 3)];
		
		cell_message.message = (Message *)object;
		return cell_message;
    }
    return nil;
}


#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"height for row: %d", [indexPath row]);
    
    NSObject *object = [cellMap objectAtIndex:[indexPath row]];
    
    // Set SentDateCell height.
    if ([object isKindOfClass:[NSDate class]]) {
        return kSentDateFontSize + 7.0f;
    }
    
    // Set MessageCell height.
    NSString * text = [object valueForKey: @"text"];
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize]
                                       constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
                                           lineBreakMode:UILineBreakModeWordWrap];
    return size.height + 17.0f;
}

// // beginUpdates & endUpdates cause the cells to get mixed up when scrolling aggressively.
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    [chatContent endUpdates];
//}

- (void) chatBarTextCleared:(ChatBar *)chatBar {
    
}

- (void) chatBar:(ChatBar *)_chatBar didChangeHeight:(CGFloat)height {
    SET_CHAT_BAR_HEIGHT(height);
    [self scrollToBottomAnimated: YES];
}

- (void) chatBar:(ChatBar *)chat BarDidChangeText:(NSString *)text
{
	if (toView) 
	{
		// Enable sendButton if chatInput and toInput has non-blank text, disable otherwise.
		if (text.length > 0 && toView.toInput.text.length > 0) {
			[chatBar enableSendButton];
		} else {
			[chatBar disableSendButton];
		}
	}
	else
	{
		// Enable sendButton if chatInput has non-blank text, disable otherwise.
		if (text.length > 0) {
			[chatBar enableSendButton];
		} else {
			[chatBar disableSendButton];
		}
	}

}

@end
