// Old
#import <AudioToolbox/AudioToolbox.h>

#import "ChatBar.h"
#import "ToView.h"

#import "Conversation.h"
//@class Message;


@interface ChatViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,  UIActionSheetDelegate,ChatBarDelegate, NSFetchedResultsControllerDelegate> 
{

    SystemSoundID receiveMessageSound;
    NSMutableArray *cellMap;
    UITableView *chatContent;
    ChatBar *chatBar;
	ToView *toView;
	float toViewHeight;
	
	NSManagedObjectContext *managedObjectContext;
    NSFetchedResultsController *fetchedResultsController;
    
}
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) Conversation *conversation;

- (id) createNewMessageWithText: (NSString*) text;
+ (NSArray *) sortDescriptors;
+ (Class) delimiterClass;
+ (Class) contentClass;

@end
