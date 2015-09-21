//
//  NYTMediaViewController.h
//  Pods
//
//  Created by Jonathan Cichon on 09.09.15.
//
//

@import UIKit;
@import AVKit;
@import MediaPlayer;

#import "NYTPhotoViewController.h"

typedef enum : NSUInteger {
    NYTMediaPlaybackStateUnknown,
    NYTMediaPlaybackStateStopped,
    NYTMediaPlaybackStatePaused,
    NYTMediaPlaybackStatePlaying,
} NYTMediaPlaybackState;

@protocol NYTPhoto;
@protocol NYTMediaViewControllerDelegate;
@protocol NYTMediaControlsDelegate;

/**
 *  The view controller controlling the display of a single media object.
 */
@interface NYTMediaViewController : UIViewController <NYTPhotoContainer>

/**
 *  The internal activity view shown while the image is loading. Set from the initializer.
 */
@property (nonatomic, readonly) UIView *loadingView;

/**
 *  The object that acts as the photo view controller's delegate.
 */
@property (nonatomic, weak) id <NYTMediaViewControllerDelegate> delegate;

/**
 * The objects that acts as the control for the media playback.
 */
@property (nonatomic, weak) id <NYTMediaControlsDelegate> controlDelegate;

/**
 *  The designated initializer that takes the photo and activity view.
 *
 *  @param photo              The photo object that this view controller manages.
 *  @param loadingView        The view to display while the photo's image loads. This view will be hidden when the image loads.
 *  @param notificationCenter The notification center on which to observe the `NYTPhotoViewControllerPhotoImageUpdatedNotification`.
 *
 *  @return A fully initialized object.
 */
- (instancetype)initWithPhoto:(id <NYTPhoto>)photo
                  loadingView:(UIView *)loadingView
                   playButton:(UIButton *)playButton
           notificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;

- (NYTMediaPlaybackState)state;
- (void)play;
- (void)pause;
- (void)stop;
- (NSTimeInterval)duration;
- (NSTimeInterval)currentTime;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTime:(NSTimeInterval)time toleranceBefore:(NSTimeInterval)toleranceBefore toleranceAfter:(NSTimeInterval)toleranceAfter;

@end

@protocol NYTMediaViewControllerDelegate <NSObject>

@optional

/**
 *  Called when a long press is recognized.
 *
 *  @param mediaViewController        The `NYTMediaViewController` instance that sent the delegate message.
 *  @param longPressGestureRecognizer The long press gesture recognizer that recognized the long press.
 */
- (void)mediaViewController:(NYTMediaViewController *)mediaViewController didLongPressWithGestureRecognizer:(UILongPressGestureRecognizer *)longPressGestureRecognizer;

/**
 *  Called on viewDidAppear.
 *
 *  @param mediaViewController        The `NYTMediaViewController` instance that sent the delegate message.
 *  @param phot                       The photo displayed by the Controller.
 */
- (void)mediaViewController:(NYTMediaViewController *)mediaViewController didShowPhoto:(id <NYTPhoto>)photo;

//- (void)mediaViewController:(NYTMediaViewController *)mediaViewController didStartPlayback:(id <NYTPhoto>)photo;

@end


@protocol NYTMediaControlsDelegate <NSObject>

@optional

- (void)mediaViewController:(NYTMediaViewController *)mediaViewController wantsControlUpdate:(NYTMediaPlaybackState)newState;

@end