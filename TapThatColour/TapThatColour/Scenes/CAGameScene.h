//
//  CAGameScene.h
//  ColorTap
//
//  Created by Cohen Adair on 2015-07-09.
//  Copyright (c) 2015 Cohen Adair. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "CABackgroundNode.h"
#import "CATapGame.h"

@interface CAGameScene : SKScene

@property UIViewController *viewController;
@property BOOL autoStart;

- (NSInteger)score;

@end
