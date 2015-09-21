//
//  NYTMediaControlsView.h
//  Pods
//
//  Created by Jonathan Cichon on 09.09.15.
//
//

#import <UIKit/UIKit.h>
#import "NYTMediaViewController.h"

@interface NYTMediaControlsView : UIView <NYTMediaControlsDelegate>

- (instancetype)initWithMediaController:(NYTMediaViewController *)controller NS_DESIGNATED_INITIALIZER;

@end
