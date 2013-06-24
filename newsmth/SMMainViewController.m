//
//  SMMainViewController.m
//  newsmth
//
//  Created by Maxwin on 13-6-11.
//  Copyright (c) 2013年 nju. All rights reserved.
//

#import "SMMainViewController.h"
#import "SMLeftViewController.h"
#import "SMMainpageViewController.h"
#import <QuartzCore/CALayer.h>

#define LEFT_SIZE   270.0f
#define ANIMATION_DURATION  0.5f

typedef enum {
    DragDirectionLeft,
    DragDirectionRight
}DragDirection;

static SMMainViewController *_instance;

@interface SMMainViewController ()<UIGestureRecognizerDelegate>
@property (strong, nonatomic) SMLeftViewController *leftViewController;
@property (strong, nonatomic) P2PNavigationController *centerViewController;
@property (assign, nonatomic) BOOL isDragging;
@property (strong, nonatomic) UIView *viewForCenterMasker;
@property (assign, nonatomic) CGFloat leftPanX;
@property (assign, nonatomic) DragDirection dragDirection;
@end

@implementation SMMainViewController

+ (SMMainViewController *)instance
{
    if (_instance == nil) {
        _instance = [[SMMainViewController alloc] init];
    }
    return _instance;
}

- (id)init
{
    if (_instance == nil) {
        _instance = [super init];
    }
    return _instance;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _leftViewController = [[SMLeftViewController alloc] init];
    _leftViewController.view.frame = self.view.bounds;
    [self.view addSubview:_leftViewController.view];
        
    SMMainpageViewController *mainpageViewController = [[SMMainpageViewController alloc] init];
    _centerViewController = [[P2PNavigationController alloc] initWithRootViewController:mainpageViewController];
    _centerViewController.view.frame = self.view.bounds;
    [self.view addSubview:_centerViewController.view];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onViewPanGesture:)];
    panGesture.delegate = self;
    [_centerViewController.view addGestureRecognizer:panGesture];
}

- (void)setRootViewController:(UIViewController *)viewController
{
    [_centerViewController popToRootViewControllerAnimated:NO];
    _centerViewController.viewControllers = @[viewController];
}


- (void)setLeftVisiable:(BOOL)visiable
{
    CGFloat endX = visiable ? LEFT_SIZE : 0;
    CGFloat length = _centerViewController.view.frame.origin.x - endX;
    CGFloat duration = ANIMATION_DURATION * fabsf(length) / LEFT_SIZE;
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = _centerViewController.view.frame;
        frame.origin.x = endX;
        _centerViewController.view.frame = frame;
    } completion:^(BOOL finished) {
        _leftViewController.view.hidden = !visiable;
    }];
    
    if (visiable) {
        if (_viewForCenterMasker == nil) {
            CGRect frame = self.view.bounds;
            frame.origin.x = LEFT_SIZE;
            _viewForCenterMasker = [[UIView alloc] initWithFrame:frame];
            [self.view addSubview:_viewForCenterMasker];
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onMaskterTap:)];
            [_viewForCenterMasker addGestureRecognizer:tapGesture];
        }
        _viewForCenterMasker.hidden = NO;
    } else {
        _viewForCenterMasker.hidden = YES;
    }
}


- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint pan = [gestureRecognizer translationInView:self.view];
    if (fabsf(pan.x) > fabsf(pan.y) && self.centerViewController.viewControllers.count <= 1) {
        _leftPanX = pan.x;
        _leftViewController.view.hidden = NO;
        return YES;
    }
    return NO;
}

- (void)onViewPanGesture:(UIPanGestureRecognizer *)gesture
{
    CGPoint pan = [gesture translationInView:self.view];
    CGRect frame = _centerViewController.view.frame;
    CGFloat delta = pan.x - _leftPanX;
    _leftPanX = pan.x;
    
    if (delta != 0) {
        _dragDirection = delta > 0 ? DragDirectionRight : DragDirectionLeft;
    }
    
    frame.origin.x += delta;
    frame.origin.x = MAX(frame.origin.x, 0);
    _centerViewController.view.frame = frame;
    
    // end gesture
    if (gesture.state == UIGestureRecognizerStateEnded
        || gesture.state == UIGestureRecognizerStateCancelled
        || gesture.state == UIGestureRecognizerStateFailed) {
        CGFloat velocity = [gesture velocityInView:self.view].x;
        if (_dragDirection == DragDirectionRight && (_centerViewController.view.frame.origin.x > self.view.bounds.size.width / 2.0f || velocity > 500)) {
            [self setLeftVisiable:YES];
        } else {
            [self setLeftVisiable:NO];
        }
    }    
}

- (void)onMaskterTap:(UITapGestureRecognizer *)gesture
{
    [self setLeftVisiable:NO];
}

@end