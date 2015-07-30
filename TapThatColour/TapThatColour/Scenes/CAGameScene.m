//
//  CAGameScene.m
//  ColorTap
//
//  Created by Cohen Adair on 2015-07-09.
//  Copyright (c) 2015 Cohen Adair. All rights reserved.
//

#import "CAGameScene.h"
#import "CAConstants.h"
#import "CAColor.h"

@interface CAGameScene()

@property (nonatomic) BOOL contentCreated;
@property (nonatomic) BOOL animationBegan;
@property (nonatomic) BOOL isGameOver; // used to prevent unwanted update: calls
@property (nonatomic) CFTimeInterval gracePeriod; // starts immediately after a color change

@property (nonatomic) CABackgroundNode *redBackgroundNode;
@property (nonatomic) CABackgroundNode *blueBackgroundNode;

@property (nonatomic) CATapGame *tapThatColor;
@property (nonatomic) NSMutableArray *buttonCheckPoints;

@end

#define kRedName @"redNode"
#define kBlueName @"blueNode"

#define kGracePeriodInSeconds 2.0
#define kGracePeriodNone -1

@implementation CAGameScene

#pragma mark - View Initializing

- (void)didMoveToView: (SKView *)view {
    if (!self.contentCreated) {
        [self createSceneContents];
        [self initButtonCheckPoints];
        self.contentCreated = YES;
        self.tapThatColor = [CATapGame withScore:0];
    }
    
    if (self.autoStart)
        [self handleBackgroundAnimation];
    
    self.gracePeriod = kGracePeriodNone;
}

#pragma mark - Events

- (void)onIncorrectTouch:(CAButtonNode *)aButton {
    id __block blockSelf = self;
    [aButton onIncorrectTouchWithCompletion:^() {
        [blockSelf segueToGameOver];
    }];
}

- (void)onColorChange:(CAColor *)newColor {
    // only call color change methods if the color actually changed
    if (![newColor isEqualToColor:self.scoreboardNode.color]) {
        [self.scoreboardNode updateColor:newColor];
        self.gracePeriod = [CAUtilities systemTime] + kGracePeriodInSeconds;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleBackgroundAnimation];
    
    // so touches on the scoreboard don't register
    if ([self touchInScoreboard:[touches anyObject]])
        return;
    
    CAButtonNode *buttonTouched = [self buttonTouched:[touches anyObject]];
    if (buttonTouched) {
        // check for correct color touch
        if ([buttonTouched.color isEqualToColor:self.tapThatColor.currentColor]) {
            if (!buttonTouched.wasTapped) {
                [self handleCorrectTouch];
                [buttonTouched onCorrectTouch];
            }
        } else
            [self handleGameOverFromButton:buttonTouched];
    }
    
}

// returns true if aTouch was inside the scoreboard
// needed so touches don't "pass-through" the scoreboard
- (BOOL)touchInScoreboard:(UITouch *)aTouch {
    CGRect f = self.scoreboardNode.frame;
    
    // need to "reverse" the y-coordinate because the scoreboard node's position starts at the bottom left of the screen rather than the top left
    f.origin.y = [CAUtilities screenSize].height - (f.origin.y + f.size.height);

    return CGRectContainsPoint(f, [aTouch locationInView:self.view]);
}

// retrieves the button at aTouch from the background nodes
- (CAButtonNode *)buttonTouched:(UITouch *)aTouch {
    CAButtonNode *btn1 = [self.blueBackgroundNode buttonAtTouch:aTouch];
    CAButtonNode *btn2 = [self.redBackgroundNode buttonAtTouch:aTouch];
    return btn1 ? btn1 : btn2;
}

// automatically called once per frame
- (void)update:(NSTimeInterval)currentTime {
    if (self.isGameOver)
        return;
    
    [self checkForMissedButtons];
    
    // reset background nodes and buttons if needed
    [self.redBackgroundNode update];
    [self.blueBackgroundNode update];
}

// ends the game if a button of the current color scrolls off the screen
- (void)checkForMissedButtons {
    // check for missed buttons if we're passed the grace period
    if ([CAUtilities systemTime] > self.gracePeriod) {
        self.gracePeriod = kGracePeriodNone;
        
        // check each checkpoint for a button node with a color equal to the current color
        for (id point in self.buttonCheckPoints) {
            id btn = [self nodeAtPoint:[point CGPointValue]];
            
            if ([btn isKindOfClass:[CAButtonNode class]]) {
                CAColor *color = (CAColor *)[btn color];
                
                if (![btn wasTapped] && [color isEqualToColor:self.tapThatColor.currentColor])
                    [self handleGameOverFromButton:btn];
            }
        }
    }
}

- (void)initButtonCheckPoints {
    CAButtonNode *dummy = [self.blueBackgroundNode anyButton];
    CGFloat radius = dummy.radius;
    CGFloat diameter = (radius * 2);
    
    self.buttonCheckPoints = [NSMutableArray array];
    
    for (int i = 0; i < BUTTONS_PER_ROW; i++) {
        CGPoint p = CGPointMake((radius + (i * diameter)), -diameter);
        [self.buttonCheckPoints addObject:[NSValue valueWithCGPoint:p]];
    }
}

// starts the background animation if it hasn't already been started
- (void)handleBackgroundAnimation {
    if (!self.animationBegan) {
        [self.redBackgroundNode startAnimating];
        [self.blueBackgroundNode startAnimating];
        self.animationBegan = YES;
        
        if (self.onGameStart)
            self.onGameStart();
    }
}

- (void)handleGameOverFromButton:(CAButtonNode *)aButton {
    [self setIsGameOver:YES];
    [self setUserInteractionEnabled:NO];
    [self stopBackgroundAnimation];
    [self.tapThatColor updateHighscore];
    [self onIncorrectTouch:aButton];
}

- (void)handleCorrectTouch {
    [self.tapThatColor incScoreBy:1];
    [self.scoreboardNode updateScoreLabel:self.tapThatColor.score];
    [self.blueBackgroundNode incAnimationSpeedBy:0.01];
    [self.redBackgroundNode incAnimationSpeedBy:0.01];
}

- (void)stopBackgroundAnimation {
    [self.redBackgroundNode stopAnimating];
    [self.blueBackgroundNode stopAnimating];
}

- (void)createSceneContents {
    self.backgroundColor = [SKColor whiteColor];
    self.scaleMode = SKSceneScaleModeAspectFit;
    
    // backgrounds
    self.redBackgroundNode =
        [CABackgroundNode withName:kRedName color:[SKColor clearColor] yStartOffset:0];
    
    self.blueBackgroundNode =
        [CABackgroundNode withName:kBlueName color:[SKColor clearColor] yStartOffset:[CAUtilities screenSize].height];
    
    [self.redBackgroundNode setSibling:self.blueBackgroundNode];
    [self.blueBackgroundNode setSibling:self.redBackgroundNode];
    
    [self addChild:self.redBackgroundNode];
    [self addChild:self.blueBackgroundNode];
    
    // scoreboard
    [self setScoreboardNode:[CAScoreboardNode withScore:0 color:[CAColor blueColor]]];
    [self addChild:self.scoreboardNode];
}

- (NSInteger)score {
    return self.tapThatColor.score;
}

- (void)togglePaused {
    self.paused = !self.paused;
    self.userInteractionEnabled = !self.paused;
}

#pragma mark - Navigation

- (void)segueToGameOver {
    [[self viewController] performSegueWithIdentifier:@"fromMainToGameOver" sender:self];
}

@end
