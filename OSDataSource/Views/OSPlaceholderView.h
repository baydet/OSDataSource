/*
 Abstract:
 
  Various placeholder views.
  
 */

#import <UIKit/UIKit.h>

/// A placeholder view that approximates the standard iOS no content view.
@interface OSPlaceholderView : UIView

@property(nonatomic, strong) UIImage *image;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *message;
@property(nonatomic, copy) NSString *buttonTitle;
@property(nonatomic, copy) void (^buttonAction)(void);

/// Initialize a placeholder view. A message is required in order to display a button.
- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title message:(NSString *)message image:(UIImage *)image buttonTitle:(NSString *)buttonTitle buttonAction:(dispatch_block_t)buttonAction;

@end

/// A placeholder view for use in the collection view. This placeholder includes the loading indicator.
@interface AAPLCollectionPlaceholderView : UICollectionReusableView

- (void)showActivityIndicator:(BOOL)show;

- (void)showPlaceholderWithTitle:(NSString *)title message:(NSString *)message image:(UIImage *)image animated:(BOOL)animated;

- (void)hidePlaceholderAnimated:(BOOL)animated;

@end