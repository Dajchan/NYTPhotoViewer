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
@property (nonatomic, retain) MPMoviePlayerController * playerController;
@property (nonatomic, retain) UIButton * playButton;
@property (nonatomic, retain) UIButton * pauseButton;
@property (nonatomic, retain) UISlider * progressSlider;
@property (nonatomic, retain) UILabel * timePlayedLabel;
@property (nonatomic, retain) UILabel * timeLeftLabel;
@property (nonatomic, retain) NSTimer * playerObservationTimer;

@end

@implementation NYTMediaControlsView

+ (UIImage *)thumbImage {
    static UIImage *thumbImage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(NYTMediaControlsViewThumbSize+4, NYTMediaControlsViewThumbSize+4), NO, [UIScreen mainScreen].scale);
        UIBezierPath * path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(2, 2, NYTMediaControlsViewThumbSize, NYTMediaControlsViewThumbSize)];
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0.5), 1, [UIColor colorWithWhite:0 alpha:0.5].CGColor);
        [[UIColor whiteColor] setFill];
        [path fill];
        thumbImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
    });
    return thumbImage;
}

- (instancetype)initWithMoviePlayer:(MPMoviePlayerController *)player {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _playerController = player;
        [self setupSubviews];
        [self evalState];
        if (player) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidChange) name:MPMoviePlayerPlaybackStateDidChangeNotification object:player];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidFinish) name:MPMoviePlayerPlaybackDidFinishNotification object:player];
        }
    }
    return self;
}

- (void)setupSubviews {
    self.playButton = [[UIButton alloc] init];
    self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.playButton setTitle:@"▶\U0000FE0E" forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(startPlayback) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.playButton];
    
    self.pauseButton = [[UIButton alloc] init];
    self.pauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pauseButton setTitle:@"❚❚" forState:UIControlStateNormal];
    [self.pauseButton addTarget:self action:@selector(pausePlayback) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.pauseButton];
    
    for (UIButton *btn in @[self.playButton, self.pauseButton]) {
        [btn.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor lightTextColor] forState:UIControlStateHighlighted];
        [btn setTitleColor:[UIColor lightTextColor] forState:UIControlStateSelected];
        [btn setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateDisabled];
    }
    
    self.timePlayedLabel = [[UILabel alloc] init];
    self.timePlayedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.timePlayedLabel];
    
    self.progressSlider = [[UISlider alloc] init];
    self.progressSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressSlider.continuous = false;
    [self.progressSlider setThumbImage:[self class].thumbImage forState:UIControlStateNormal];
    [self.progressSlider addTarget:self action:@selector(changeTime) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.progressSlider];
    
    self.timeLeftLabel = [[UILabel alloc] init];
    self.timeLeftLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.timeLeftLabel];
    
    for (UILabel *lbl in @[self.timePlayedLabel, self.timeLeftLabel]) {
        lbl.font = [UIFont fontWithName:@"Courier New" size:11];
        lbl.textColor = [UIColor lightTextColor];
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
    if (self.playerController.isPreparedToPlay) {
        
        if (self.playerController.playbackState == MPMoviePlaybackStatePlaying) {
            self.playButton.hidden = true;
            self.pauseButton.hidden = false;
        } else {
            self.playButton.hidden = false;
            self.pauseButton.hidden = true;
        }
        
        NSTimeInterval duration = self.playerController.duration;
        NSTimeInterval currentTime = self.playerController.currentPlaybackTime;
        NSTimeInterval timeLeft = duration - currentTime;
        
        [self updateLabel:self.timePlayedLabel time:currentTime];
        [self updateLabel:self.timeLeftLabel time:timeLeft];
        self.progressSlider.maximumValue = duration;
        self.progressSlider.minimumValue = 0;
        self.progressSlider.value = currentTime;
        self.playButton.enabled = true;
    } else {
        self.timePlayedLabel.text = @"-:--";
        self.timeLeftLabel.text = @"-:--";
        self.playButton.enabled = false;
        self.pauseButton.hidden = true;
    }
    [self evalTimer];
}

- (void)evalTimer {
    @synchronized(self) {
        if (self.playerController.playbackState == MPMoviePlaybackStatePlaying) {
            if (!_playerObservationTimer) {
                _playerObservationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(evalState) userInfo:nil repeats:YES];
            }
        } else {
            [_playerObservationTimer invalidate];
            _playerObservationTimer = nil;
        }
    }
}

- (void)updateLabel:(UILabel *)label time:(NSTimeInterval)time {
    int minutes = time/60;
    int seconds = MAX(0, MIN(59,time - (minutes*60)));
    [label setText:[NSString stringWithFormat:@"%d:%02d", minutes, seconds]];
}

- (void)startPlayback {
//    NSLog(@"startPlayback");
    [self.playerController play];
    [self evalState];
}

- (void)pausePlayback {
    [self.playerController pause];
    [self evalState];
//    NSLog(@"pausePlayback");
}

- (void)playbackDidChange {
//    NSLog(@"playbackDidChange");
    [self evalState];
}

- (void)playbackDidFinish {
//    NSLog(@"playbackDidFinish");
    [self evalState];
}

- (void)changeTime {
//    NSLog(@"changeTime: %f", self.progressSlider.value);
    [self.playerController setCurrentPlaybackTime:self.progressSlider.value];
//    [self evalState];
}

- (void)dealloc {
    if (self.playerController) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.playerController];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.playerController];
    }
}

@end

