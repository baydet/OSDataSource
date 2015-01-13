/*
 Abstract:
 
  AAPLLoadableContentStateMachine — This is the state machine that manages transitions for all loadable content.
  AAPLLoading — This is a signalling object used to simplify transitions on the statemachine and provide update blocks.
  AAPLContentLoading — A protocol adopted by the AAPLDataSource class for loading content.
  
 */

#import "OSStateMachine.h"

static NSString *const AAPLLoadStateInitial = @"Initial";
static NSString *const AAPLLoadStateLoadingContent = @"LoadingState";
static NSString *const AAPLLoadStateRefreshingContent = @"RefreshingState";
static NSString *const AAPLLoadStateContentLoaded = @"LoadedState";
static NSString *const AAPLLoadStateNoContent = @"NoContentState";
static NSString *const AAPLLoadStateError = @"ErrorState";
static NSString *const AAPLLoadStateFirstTimeLoad = @"FirstTimeLoad";

/// A block that performs updates on the object that is loading. The object parameter is the original object that received the -loadContentWithBlock: message.
typedef void (^AAPLLoadingUpdateBlock)(id object);

/// A specialization of ITCStateMachine for content loading.
@interface AAPLLoadableContentStateMachine : OSStateMachine
@end

/// A helper class passed to the content loading block of an AAPLLoadableContentViewController.
@interface AAPLLoading : NSObject
/// Signals that this result should be ignored. Sends a nil value for the state to the completion handler.
- (void)ignore;

/// Signals that loading is complete with no errors. This triggers a transition to the Loaded state.
- (void)done;

/// Signals that loading failed with an error. This triggers a transition to the Error state.
- (void)doneWithError:(NSError *)error;

/// Signals that loading is complete, transitions into the Loaded state and then runs the update block.
- (void)updateWithContent:(AAPLLoadingUpdateBlock)update;

/// Signals that loading completed with no content, transitions to the No Content state and then runs the update block.
- (void)updateWithNoContent:(AAPLLoadingUpdateBlock)update;

/// Is this the current loading operation? When -loadContentWithBlock: is called it should inform previous instances of AAPLLoading that they are no longer the current instance.
@property(nonatomic, getter=isCurrent) BOOL current;

- (void)updateWithContentFromEmpty:(AAPLLoadingUpdateBlock)update;

/// create a new loading helper
+ (instancetype)loadingWithCompletionHandler:(void (^)(NSString *state, NSError *error, AAPLLoadingUpdateBlock update))handler;

@end


typedef void (^AAPLLoadingBlock)(AAPLLoading *loading);


/// A protocol that defines content loading behavior
@protocol AAPLContentLoading <NSObject>
/// The current state of the content loading operation
@property(nonatomic, copy) NSString *loadingState;
/// Any error that occurred during content loading. Valid only when loadingState == ITCLoadStateError.
@property(nonatomic, strong) NSError *loadingError;

/// Public method used to begin loading the content.
- (void)loadContent;

/// Public method used to reset the content of the receiver.
- (void)resetContent;

/// Method used by implementers of -loadContent to manage the loading operation. Usually implemented by the base class that adopts ITCContentLoading.
- (void)loadContentWithBlock:(AAPLLoadingBlock)block;
@end

