//
//  CAGameOverViewController.m
//  TapThatColour
//
//  Created by Cohen Adair on 2015-07-22.
//  Copyright (c) 2015 Cohen Adair. All rights reserved.
//

#import "CAGameOverViewController.h"
#import "CAGameCenterManager.h"
#import "CATapGame.h"
#import "CAAppDelegate.h"
#import "CAUserSettings.h"
#import "CAUtilities.h"
#import "CAConstants.h"

@interface CAGameOverViewController ()

@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *highscoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *difficultyLabel;

@property (nonatomic) BOOL muted;

@end

@implementation CAGameOverViewController

- (CATapGame *)tapGame {
    return [(CAAppDelegate *)[[UIApplication sharedApplication] delegate] tapGame];
}

#pragma mark - Initializing

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.scoreLabel setText:[[self tapGame] scoreAsString]];
    
    [CAUtilities makeNavigationBarTransparent:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self initHighscoreLabel];
    [self initDifficultyLabel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)initHighscoreLabel {
    [self.highscoreLabel setText:[NSString stringWithFormat:@"Highscore: %ld", (long)[[CAUserSettings sharedSettings] highscore]]];
}

- (void)initDifficultyLabel {
    [self.difficultyLabel setText:[[self tapGame] difficultyAsString]];
}

#pragma mark - Events

- (IBAction)tapShareButton:(UIButton *)aSender {
    NSArray *items = @[[NSString stringWithFormat:@"I just scored %ld on #TapThatColour! Check it out on the App Store!", (long)[[self tapGame] score]]];
    [CAUtilities presentShareActivityForViewController:self items:items];
}

- (IBAction)tapRateButton:(UIButton *)aSender {
    NSString *stringUrl = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%d", APP_ID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringUrl]];
}

- (IBAction)tapLeaderboardsButton:(UIButton *)aSender {
    [[CAGameCenterManager sharedManager] presentLeaderboardsInViewController:self];
}

- (IBAction)tapIcons8Button:(UIButton *)sender {
    [CAUtilities openUrl:@"https://icons8.com/"];
}

#pragma mark - Game Center Delgate

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

@end