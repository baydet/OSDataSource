/*
 Abstract:
 
  AAPLLoadableContentStateMachine — This is the state machine that manages transitions for all loadable content.
  AAPLLoading — This is a signalling object used to simplify transitions on the statemachine and provide update blocks.
  AAPLContentLoading — A protocol adopted by the AAPLDataSource class for loading content.
  
 */

#import <libkern/OSAtomic.h>
#import "AAPLContentLoading.h"

#define DEBUG_ITCLOADING 0


@implementation AAPLLoadableContentStateMachine

- (instancetype)init
{
    self = [super init];
    self.currentState = AAPLLoadStateInitial;
    self.validTransitions = @{
            AAPLLoadStateInitial : @[AAPLLoadStateLoadingContent],
            AAPLLoadStateLoadingContent : @[AAPLLoadStateFirstTimeLoad, AAPLLoadStateContentLoaded, AAPLLoadStateNoContent, AAPLLoadStateError],
            AAPLLoadStateRefreshingContent : @[AAPLLoadStateFirstTimeLoad, AAPLLoadStateContentLoaded, AAPLLoadStateNoContent, AAPLLoadStateError],
            AAPLLoadStateContentLoaded : @[AAPLLoadStateRefreshingContent, AAPLLoadStateNoContent, AAPLLoadStateError],
            AAPLLoadStateFirstTimeLoad : @[AAPLLoadStateRefreshingContent, AAPLLoadStateNoContent, AAPLLoadStateError],
            AAPLLoadStateNoContent : @[AAPLLoadStateRefreshingContent, AAPLLoadStateContentLoaded, AAPLLoadStateFirstTimeLoad, AAPLLoadStateError],
            AAPLLoadStateError : @[AAPLLoadStateLoadingContent, AAPLLoadStateRefreshingContent, AAPLLoadStateNoContent, AAPLLoadStateContentLoaded, AAPLLoadStateFirstTimeLoad]
    };
    return self;
}

@end


@interface AAPLLoading ()
@property(nonatomic, copy) void (^block)(NSString *newState, NSError *error, AAPLLoadingUpdateBlock update);
@end

@implementation AAPLLoading
#if DEBUG
{
    int32_t _complete;
}
#endif

+ (instancetype)loadingWithCompletionHandler:(void (^)(NSString *state, NSError *error, AAPLLoadingUpdateBlock update))handler
{
    NSParameterAssert(handler != nil);
    AAPLLoading *loading = [[self alloc] init];
    loading.block = handler;
    loading.current = YES;
    return loading;
}

#if DEBUG

- (void)aaplLoadingDebugDealloc
{
    if (OSAtomicCompareAndSwap32(0, 1, &_complete))
#if DEBUG_ITCLOADING
        NSAssert(false, @"No completion methods called on AAPLLoading instance before dealloc called.");
#else
        NSLog(@"No completion methods called on AAPLLoading instance before dealloc called. Break in -[AAPLLoading aaplLoadingDebugDealloc] to debug this.");
#endif
}

- (void)dealloc
{
    // make this easier to debug by having a separate method for a breakpoint.
    [self aaplLoadingDebugDealloc];
}

#endif

- (void)_doneWithNewState:(NSString *)newState error:(NSError *)error update:(AAPLLoadingUpdateBlock)update
{
#if DEBUG
    if (!OSAtomicCompareAndSwap32(0, 1, &_complete))
        NSAssert(false, @"completion method called more than once");
#endif

    void (^block)(NSString *state, NSError *error, AAPLLoadingUpdateBlock update) = _block;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (block)
            block(newState, error, update);
    });

    _block = nil;
}

- (void)ignore
{
    [self _doneWithNewState:nil error:nil update:nil];
}

- (void)done
{
    [self _doneWithNewState:AAPLLoadStateFirstTimeLoad error:nil update:nil];
}

- (void)updateWithContent:(AAPLLoadingUpdateBlock)update
{
    [self _doneWithNewState:AAPLLoadStateContentLoaded error:nil update:update];
}

- (void)doneWithError:(NSError *)error
{
    NSString *newState = error ? AAPLLoadStateError : AAPLLoadStateContentLoaded;
    [self _doneWithNewState:newState error:error update:nil];
}

- (void)updateWithNoContent:(AAPLLoadingUpdateBlock)update
{
    [self _doneWithNewState:AAPLLoadStateNoContent error:nil update:update];
}

- (void)updateWithContentFromEmpty:(AAPLLoadingUpdateBlock)update
{
    [self _doneWithNewState:AAPLLoadStateFirstTimeLoad error:nil update:update];
}
@end

