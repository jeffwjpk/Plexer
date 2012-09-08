//
//  PXTeam.h
//  Plexer
//
//  Created by David Owens II on 9/7/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PXGame.h"

@interface PXTeam : NSObject

@property (copy) NSString *name;
@property (weak) PXGame *game;

@end