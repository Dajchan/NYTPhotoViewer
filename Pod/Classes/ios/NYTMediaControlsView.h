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
@property (nonatomic, strong) UIFont *progressLabelFont UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *progressLabelColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIImage *playIcon UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIImage *pausIcon UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIImage *progressSliderThumb UI_APPEARANCE_SELECTOR;

- (instancetype)initWithMediaController:(NYTMediaViewController *)controller NS_DESIGNATED_INITIALIZER;

@end
