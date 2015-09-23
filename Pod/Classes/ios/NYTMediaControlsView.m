//
//  NYTMediaControlsView.m
//  Pods
//
//  Created by Jonathan Cichon on 09.09.15.
//
//

#import "NYTMediaControlsView.h"

static const CGFloat NYTMediaControlsViewHorizontalMargin = 12.0;
static const CGFloat NYTMediaControlsViewVerticalMargin = 10;
static const CGFloat NYTMediaControlsViewButtonSize = 30;
static const CGFloat NYTMediaControlsViewLabelWidth = 40;
static const CGFloat NYTMediaControlsViewThumbSize = 18;

@interface NYTMediaControlsView ()
@property (nonatomic, retain) NYTMediaViewController *mediaController;
@property (nonatomic, retain) UIButton * playButton;
@property (nonatomic, retain) UIButton * pauseButton;
@property (nonatomic, retain) UISlider * progressSlider;
@property (nonatomic, retain) UILabel * timePlayedLabel;
@property (nonatomic, retain) UILabel * timeLeftLabel;

@end

static inline UIImage *NYTMediaControlsViewThumbImage() {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(NYTMediaControlsViewThumbSize+4, NYTMediaControlsViewThumbSize+4), NO, [UIScreen mainScreen].scale);
    UIBezierPath * path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(2, 2, NYTMediaControlsViewThumbSize, NYTMediaControlsViewThumbSize)];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0.5), 1, [UIColor colorWithWhite:0 alpha:0.5].CGColor);
    [[UIColor whiteColor] setFill];
    [path fill];
    UIImage * thumbImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumbImage;
}

static inline UIImage *NYTMediaControlsIcon(NSString *iconString) {
    CGRect drawRect = CGRectMake(0,0,NYTMediaControlsViewButtonSize, NYTMediaControlsViewButtonSize);
    UIGraphicsBeginImageContextWithOptions(drawRect.size, NO, [UIScreen mainScreen].scale);
    [iconString drawInRect:drawRect withAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16], NSForegroundColorAttributeName : [UIColor whiteColor]}];
    UIImage * icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return icon;
}

static inline UIImage *NYTMediaControlsViewPlayIcon() {
    return NYTMediaControlsIcon(@"▶\U0000FE0E");
}

static inline UIImage *NYTMediaControlsViewPauseIcon() {
    return NYTMediaControlsIcon(@"❚❚");
}

@implementation NYTMediaControlsView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithMediaController:nil];
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithMediaController:nil];
}

- (instancetype)initWithMediaController:(NYTMediaViewController *)controller {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _mediaController = controller;
        [_mediaController setControlDelegate:self];
        _progressLabelFont = [UIFont fontWithName:@"Courier New" size:11];
        _progressLabelColor = [UIColor lightTextColor];
        _progressSliderThumb = NYTMediaControlsViewThumbImage();
        _playIcon = NYTMediaControlsViewPlayIcon();
        _pausIcon = NYTMediaControlsViewPauseIcon();
        
        [self setupSubviews];
        [self evalState];
    }
    return self;
}

- (void)setupSubviews {
    self.playButton = [[UIButton alloc] init];
    self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.playButton setImage:self.playIcon forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(startPlayback) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.playButton];
    
    self.pauseButton = [[UIButton alloc] init];
    self.pauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pauseButton setImage:self.pausIcon forState:UIControlStateNormal];
    [self.pauseButton addTarget:self action:@selector(pausePlayback) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.pauseButton];
    
    self.timePlayedLabel = [[UILabel alloc] init];
    self.timePlayedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.timePlayedLabel];
    
    self.progressSlider = [[UISlider alloc] init];
    self.progressSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressSlider.continuous = false;
    [self.progressSlider setThumbImage:self.progressSliderThumb forState:UIControlStateNormal];
    [self.progressSlider addTarget:self action:@selector(changeTime) forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self action:@selector(sliderEnd) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    [self.progressSlider addTarget:self action:@selector(sliderStart) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.progressSlider];
    
    self.timeLeftLabel = [[UILabel alloc] init];
    self.timeLeftLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.timeLeftLabel];
    
    for (UILabel *lbl in @[self.timePlayedLabel, self.timeLeftLabel]) {
        lbl.font = self.progressLabelFont;
        lbl.textColor = self.progressLabelColor;
        lbl.textAlignment = NSTextAlignmentRight;
    }
    
    [self setupPlayButton];
    [self setupPauseButton];
    [self setupTimePlayedLabel];
    [self setupTimeLeftLabel];
    [self setupProgressSlider];
    
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
}

- (void)setupPlayButton {
    NSLayoutConstraint * topConstraint = [NSLayoutConstraint constraintWithItem:self.playButton
                                                                      attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                                                         toItem:self attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0 constant:NYTMediaControlsViewVerticalMargin];
    
    NSLayoutConstraint * bottomConstraint = [NSLayoutConstraint constraintWithItem:self.playButton
                                                                         attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
                                                                            toItem:self attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0 constant:-NYTMediaControlsViewVerticalMargin];
    
    NSLayoutConstraint * leftConstraint = [NSLayoutConstraint constraintWithItem:self.playButton
                                                                       attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
                                                                          toItem:self attribute:NSLayoutAttributeLeft
                                                                      multiplier:1.0 constant:NYTMediaControlsViewHorizontalMargin]; 
    
    NSLayoutConstraint * widthConstraint = [NSLayoutConstraint constraintWithItem:self.playButton
                                                                        attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil attribute:0
                                                                       multiplier:1.0 constant:NYTMediaControlsViewButtonSize];
    
    NSLayoutConstraint * heightConstraint = [NSLayoutConstraint constraintWithItem:self.playButton
                                                                         attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil attribute:0
                                                                        multiplier:1.0 constant:NYTMediaControlsViewButtonSize];
    
    [self addConstraints:@[leftConstraint, topConstraint, bottomConstraint, widthConstraint, heightConstraint]];
}

- (void)setupPauseButton {
    NSLayoutConstraint * widthConstraint = [NSLayoutConstraint constraintWithItem:self.pauseButton
                                                                        attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.playButton attribute:NSLayoutAttributeWidth
                                                                       multiplier:1.0 constant:0];
    
    NSLayoutConstraint * heightConstraint = [NSLayoutConstraint constraintWithItem:self.pauseButton
                                                                         attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.playButton attribute:NSLayoutAttributeHeight
                                                                        multiplier:1.0 constant:0];
    
    NSLayoutConstraint * xPositionConstraint = [NSLayoutConstraint constraintWithItem:self.pauseButton
                                                                            attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.playButton attribute:NSLayoutAttributeCenterX
                                                                           multiplier:1.0 constant:0];
    
    NSLayoutConstraint * yPositionConstraint = [NSLayoutConstraint constraintWithItem:self.pauseButton
                                                                            attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.playButton attribute:NSLayoutAttributeCenterY
                                                                           multiplier:1.0 constant:0];
    
    [self addConstraints:@[widthConstraint, heightConstraint, xPositionConstraint, yPositionConstraint]];
}

- (void)setupTimePlayedLabel {
    NSLayoutConstraint * leftConstraint = [NSLayoutConstraint constraintWithItem:self.timePlayedLabel
                                                                       attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.playButton attribute:NSLayoutAttributeRight
                                                                      multiplier:1.0 constant:NYTMediaControlsViewHorizontalMargin * 2];
    
    NSLayoutConstraint * heightConstraint = [NSLayoutConstraint constraintWithItem:self.timePlayedLabel
                                                                         attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.playButton attribute:NSLayoutAttributeHeight
                                                                        multiplier:1.0 constant:0];
    
    NSLayoutConstraint * yPositionConstraint = [NSLayoutConstraint constraintWithItem:self.timePlayedLabel
                                                                            attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.playButton attribute:NSLayoutAttributeCenterY
                                                                           multiplier:1.0 constant:0];
    
    NSLayoutConstraint * widthConstraint = [NSLayoutConstraint constraintWithItem:self.timePlayedLabel
                                                                        attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil attribute:0
                                                                       multiplier:1.0 constant:NYTMediaControlsViewLabelWidth];
    
    [self addConstraints:@[leftConstraint, widthConstraint, heightConstraint, yPositionConstraint]];
}

- (void)setupTimeLeftLabel {
    NSLayoutConstraint * rightConstraint = [NSLayoutConstraint constraintWithItem:self.timeLeftLabel
                                                                        attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
                                                                           toItem:self attribute:NSLayoutAttributeRight
                                                                       multiplier:1.0 constant:-NYTMediaControlsViewHorizontalMargin];
    
    NSLayoutConstraint * heightConstraint = [NSLayoutConstraint constraintWithItem:self.timeLeftLabel
                                                                         attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.playButton attribute:NSLayoutAttributeHeight
                                                                        multiplier:1.0 constant:0];
    
    NSLayoutConstraint * yPositionConstraint = [NSLayoutConstraint constraintWithItem:self.timeLeftLabel
                                                                            attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.playButton attribute:NSLayoutAttributeCenterY
                                                                           multiplier:1.0 constant:0];
    
    NSLayoutConstraint * widthConstraint = [NSLayoutConstraint constraintWithItem:self.timeLeftLabel
                                                                        attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil attribute:0
                                                                       multiplier:1.0 constant:NYTMediaControlsViewLabelWidth];
    
    [self addConstraints:@[rightConstraint, widthConstraint, heightConstraint, yPositionConstraint]];
}

- (void)setupProgressSlider {
    NSLayoutConstraint * leftConstraint = [NSLayoutConstraint constraintWithItem:self.progressSlider
                                                                       attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.timePlayedLabel attribute:NSLayoutAttributeRight
                                                                      multiplier:1.0 constant:NYTMediaControlsViewHorizontalMargin / 2.0];
    
    NSLayoutConstraint * heightConstraint = [NSLayoutConstraint constraintWithItem:self.progressSlider
                                                                         attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.playButton attribute:NSLayoutAttributeHeight
                                                                        multiplier:1.0 constant:0];
    
    NSLayoutConstraint * rightConstraint = [NSLayoutConstraint constraintWithItem:self.progressSlider
                                                                        attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.timeLeftLabel attribute:NSLayoutAttributeLeft
                                                                       multiplier:1.0 constant:-(NYTMediaControlsViewHorizontalMargin / 2.0)];
    
    NSLayoutConstraint * yPositionConstraint = [NSLayoutConstraint constraintWithItem:self.progressSlider
                                                                            attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.playButton attribute:NSLayoutAttributeCenterY
                                                                           multiplier:1.0 constant:0];
    
    [self addConstraints:@[leftConstraint, heightConstraint, rightConstraint, yPositionConstraint]];
}

- (void)evalState {
    NYTMediaPlaybackState state = [self mediaController].state;
    if (state > NYTMediaPlaybackStateUnknown) {
        if (state == NYTMediaPlaybackStatePlaying || state == NYTMediaPlaybackStateSeeking) {
            self.playButton.hidden = true;
            self.pauseButton.hidden = false;
        } else {
            self.playButton.hidden = false;
            self.pauseButton.hidden = true;
        }
        
        self.playButton.enabled = true;
        
        NSTimeInterval duration = self.mediaController.duration;
        NSTimeInterval currentTime = self.mediaController.currentTime;
        if (self.progressSlider.maximumValue != duration) {
            self.progressSlider.maximumValue = duration;
            [self updateTimeLabels];
        }
        
        if (state != NYTMediaPlaybackStateSeeking) {
            if (currentTime > self.progressSlider.value) {
                self.progressSlider.value = currentTime;
                [self updateTimeLabels];
            }
        }
    } else {
        self.timePlayedLabel.text = @"-:--";
        self.timeLeftLabel.text = @"-:--";
        self.playButton.enabled = false;
        self.pauseButton.hidden = true;
    }
}

- (void)updateTimeLabels {
    NSTimeInterval duration = self.progressSlider.maximumValue;
    NSTimeInterval currentTime = self.progressSlider.value;
    NSTimeInterval timeLeft = duration - currentTime;
    [self updateLabel:self.timePlayedLabel time:currentTime];
    [self updateLabel:self.timeLeftLabel time:timeLeft];
}

- (void)updateLabel:(UILabel *)label time:(NSTimeInterval)time {
    int minutes = time/60;
    int seconds = MAX(0, MIN(59,time - (minutes*60)));
    [label setText:[NSString stringWithFormat:@"%d:%02d", minutes, seconds]];
}

- (void)startPlayback {
    [self.mediaController play];
    [self evalState];
}

- (void)pausePlayback {
    [self.mediaController pause];
    [self evalState];
}

- (void)sliderStart {
    [self.mediaController startManualSeek];
}

- (void)sliderEnd {
    CGFloat value = floor(self.progressSlider.value);
    if (value) {
        [self.mediaController endManualSeek:value];
    } else {
        [self.mediaController endManualSeek:value];
    }
}

- (void)changeTime {
    [self updateTimeLabels];
}

- (void)mediaViewController:(NYTMediaViewController *)mediaViewController wantsControlUpdate:(NYTMediaPlaybackState)newState {
    [self evalState];
}

@end

