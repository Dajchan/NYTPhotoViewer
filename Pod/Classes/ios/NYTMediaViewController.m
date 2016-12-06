//
//  NYTMediaViewController.m
//  Pods
//
//  Created by Jonathan Cichon on 09.09.15.
//
//

#import "NYTMediaViewController.h"
#import "NYTPhoto.h"
@import AVFoundation;

@interface NYTPlayButton : UIButton

@end

@interface NYTMediaViewController ()
@property (nonatomic) id <NYTPhoto> photo;
@property (nonatomic) UIView *loadingView;
@property (nonatomic) UIImageView *previewView;
@property (nonatomic) UIView *playerView;
@property (nonatomic) UIButton *playButton;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) NSNotificationCenter *notificationCenter;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic) BOOL seekSeasionActive;

- (void)updateView;
- (void)updateControls;

@end

@implementation NYTMediaViewController

#pragma mark - NSObject

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_notificationCenter removeObserver:self];
    if (_timeObserver) {
        [_player removeTimeObserver:_timeObserver];
    }
}

#pragma mark - UIViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithPhoto:nil loadingView:nil playButton:nil notificationCenter:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithPhoto:nil loadingView:nil playButton:nil notificationCenter:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_previewView setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:_previewView];
    
    _playerView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_playerView];
    
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [_playerView.layer addSublayer:_playerLayer];
    
    [self.notificationCenter addObserver:self selector:@selector(photoImageUpdatedWithNotification:) name:NYTPhotoViewControllerPhotoImageUpdatedNotification object:nil];
    
    //    [self.view addSubview:self.loadingView];
    //    [self.loadingView sizeToFit];
    
    
    [self.view addSubview:self.playButton];
    [self.playButton sizeToFit];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _previewView.frame = self.view.bounds;
    
    _playerView.frame = self.view.bounds;
    _playerLayer.frame = _playerView.bounds;
    
    //    [self.loadingView sizeToFit];
    //    self.loadingView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    
    [self.playButton sizeToFit];
    self.playButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    
    [self updateView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.delegate respondsToSelector:@selector(mediaViewController:didShowPhoto:)]) {
        [self.delegate mediaViewController:self didShowPhoto:self.photo];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
}

#pragma mark - NYTPhotoViewController

- (instancetype)initWithPhoto:(id <NYTPhoto>)photo loadingView:(UIView *)loadingView playButton:(UIButton *)playButton notificationCenter:(NSNotificationCenter *)notificationCenter {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _photo = photo;
        
        UIImage *photoImage = photo.image ?: photo.placeholderImage;
        
        _previewView = [[UIImageView alloc] initWithImage:photoImage];
        
        if (!photo.image) {
            [self setupLoadingView:loadingView];
        }
        
        if (photo.movieURL) {
            [self setupPlayButton:playButton];
        }
        
        _notificationCenter = notificationCenter;
        
        [self setupPlayer];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(pause) name:UIApplicationWillResignActiveNotification object:nil];
    }
    
    return self;
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setupLoadingView:(UIView *)loadingView {
    self.loadingView = loadingView;
    if (!loadingView) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [activityIndicator startAnimating];
        self.loadingView = activityIndicator;
    }
}

- (void)setupPlayButton:(UIButton *)playButton {
    if (!playButton) {
        playButton = [[NYTPlayButton alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    }
    [playButton sizeToFit];
    [playButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    self.playButton = playButton;
}

- (void)photoImageUpdatedWithNotification:(NSNotification *)notification {
    id <NYTPhoto> photo = notification.object;
    if ([photo conformsToProtocol:@protocol(NYTPhoto)] && [photo isEqual:self.photo]) {
        [self updateView];
    }
}

- (void)updateView {
    UIImage *image = self.photo.image;
    self.previewView.image = image;
    [self updateControls];
}

- (void)updateControls {
    NYTMediaPlaybackState state = [self state];
    if (state == NYTMediaPlaybackStateUnknown) {
        self.playerView.hidden = true;
        self.previewView.hidden = false;
    } else {
        self.playerView.hidden = false;
        self.previewView.hidden = true;
    }
    
    if ([self.controlDelegate respondsToSelector:@selector(mediaViewController:wantsControlUpdate:)]) {
        [self.controlDelegate mediaViewController:self wantsControlUpdate:state];
    }
}

- (UIView *)presentingView {
    return self.previewView;
}

#pragma mark - Movie playback

- (void)setupPlayer {
    if (!self.player && self.photo.movieURL) {
        
        _player = [[AVPlayer alloc] initWithURL:self.photo.movieURL];
        
        __weak NYTMediaViewController *weakSelf = self;
        _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            [weakSelf updateControls];
        }];
    }
}

- (NYTMediaPlaybackState)state {
    if (self.seekSeasionActive) {
        return NYTMediaPlaybackStateSeeking;
    }
    NYTMediaPlaybackState state = NYTMediaPlaybackStateUnknown;
    if (self.player.status == AVPlayerStatusReadyToPlay) {
        if (self.player.rate > 0) {
            state = NYTMediaPlaybackStatePlaying;
        } else if ([self currentTime]) {
            state = NYTMediaPlaybackStatePaused;
        } else {
            state = NYTMediaPlaybackStateStopped;
        }
    }
    return state;
}

- (void)play {
    [_player play];
    self.playButton.hidden = true;
}

- (void)pause {
    [_player pause];
}

- (void)stop {
    [_player pause];
    [_player seekToTime:kCMTimeZero];
}

- (NSTimeInterval)duration {
    if (_player.currentItem) {
        CMTime duration = _player.currentItem.duration;
        if (CMTIME_IS_VALID(duration) && !CMTIME_IS_INDEFINITE(duration)) {
            return duration.value/duration.timescale;
        }
    }
    return 0;
}

- (NSTimeInterval)currentTime {
    CMTime time = _player.currentTime;
    return time.value/time.timescale;
}

- (void)seekToTime:(NSTimeInterval)time {
    [self seekToTime:time toleranceBefore:0 toleranceAfter:0];
}

- (void)seekToTime:(NSTimeInterval)time toleranceBefore:(NSTimeInterval)toleranceBefore toleranceAfter:(NSTimeInterval)toleranceAfter {
    CMTime before = kCMTimeZero;
    CMTime after = kCMTimeZero;
    if (toleranceBefore) {
        before = CMTimeMakeWithSeconds(toleranceBefore, 1.0);
    }
    if (toleranceAfter) {
        after = CMTimeMakeWithSeconds(toleranceAfter, 1.0);
    }
    
    [_player seekToTime:CMTimeMakeWithSeconds(time, 1.0) toleranceBefore:before toleranceAfter:after];
}

- (void)startManualSeek {
    self.seekSeasionActive = true;
    [self pause];
}

- (void)endManualSeek:(NSTimeInterval)time {
    [self seekToTime:time];
    self.seekSeasionActive = false;
    [self play];
}

@end


@implementation NYTPlayButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setTitle:@"▶\U0000FE0E" forState:UIControlStateNormal];
        [self.titleLabel setFont:[UIFont systemFontOfSize:40]];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [self setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 0)];
        [self.layer setCornerRadius:32];
        [self.layer setBorderColor:[[UIColor whiteColor] CGColor]];
        [self.layer setBorderWidth:2];
        [self setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(64, 64);
}

@end
