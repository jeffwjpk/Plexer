//
//  PXApplication.m
//  Plexer
//
//  Created by David Owens II on 9/30/12.
//  Copyright (c) 2012 Kiad Software. All rights reserved.
//

#import "PXApplication.h"
#import "PXTeamMember.h"
#import "PXWorldOfWarcraftApplication.h"

NSString * const PXApplicationDisplayNameKey                = @"PXApplicationDisplayNameKey";
NSString * const PXApplicationClassNameKey                  = @"PXApplicationClassNameKey";
NSString * const PXApplicationLaunchPathKey                 = @"PXApplicationLaunchPathKey";
NSString * const PXApplicationInstallPathKey                = @"PXApplicationInstallPathKey";
NSString * const PXApplicationFilesToVirtualizeKey          = @"PXApplicationFilesToVirtualizeKey";
NSString * const PXApplicationFilesToCopyKey                = @"PXApplicationFilesToCopyKey";

NSString const * PXApplicationWindowBoundsKey               = @"PXApplicationWindowBoundsKey";
NSString const * PXVirtualizedApplicationLaunchPathKey      = @"PXVirtualizedApplicationLaunchPathKey";


@implementation PXApplication

+ (NSArray *)supportedApplications {
    static NSMutableArray *applications = nil;
    if (applications == nil) {
        applications = [[NSMutableArray alloc] init];
        
        for (NSDictionary *dict in [[NSUserDefaults standardUserDefaults] arrayForKey:@"PXSupportedGamesKey"]) {
            NSString *className = dict[PXApplicationClassNameKey];
            if (className != nil) {
                [applications addObject:[[NSClassFromString(className) alloc] initWithDictionary:dict]];
            }
            else {
                [applications addObject:[[PXApplication alloc] initWithDictionary:dict]];
            }
        }
    }
    
    return applications;
}

+ (PXApplication *)applicationWithName:(NSString *)name
{
    for (PXApplication *application in [PXApplication supportedApplications]) {
        if ([application.displayName isEqualToString:name] == YES) {
            return application;
        }
    }
    
    return nil;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        _displayName = [dictionary[PXApplicationDisplayNameKey] copy];
        _launchPath = [dictionary[PXApplicationLaunchPathKey] copy];
        _installPath = [dictionary[PXApplicationInstallPathKey] copy];
        _itemsToVirtualize = [dictionary[PXApplicationFilesToVirtualizeKey] copy];
        _itemsToCopy = [dictionary[PXApplicationFilesToCopyKey] copy];
    }
    
    return self;
}

- (NSRunningApplication *)launchWithOptions:(NSDictionary *)options
{
    NSString *applicationLaunchPath = [self.launchPath stringByStandardizingPath];
    
    NSString *virtualizedPath = options[PXVirtualizedApplicationLaunchPathKey];
    if (virtualizedPath != nil) {
        [self virtualizeApplicationWithOptions:options removeExisting:NO];
        applicationLaunchPath = [virtualizedPath stringByStandardizingPath];
    }
    
    if ([self findRunningApplicationAtPath:applicationLaunchPath] == nil) {
        [[NSWorkspace sharedWorkspace] launchApplication:applicationLaunchPath];
        [NSThread sleepForTimeInterval:2];
    }
    
    //
    // NOTE: WoW does not provide the notifications to handle NSWorkspaceDidLaunchApplicationNotification so we must search for it.
    //
    return [self findRunningApplicationAtPath:applicationLaunchPath];
}

#pragma mark - Helper methods

- (NSRunningApplication *)findRunningApplicationAtPath:(NSString *)path
{
    for (NSRunningApplication *application in [[NSWorkspace sharedWorkspace] runningApplications]) {
        NSString *runningApplicationPath = [[application.bundleURL path] stringByStandardizingPath];
        
        if ([runningApplicationPath isEqualToString:path]) {
            return application;
        }
    }
    
    return nil;
}

- (void)virtualizeApplicationWithOptions:(NSDictionary *)options removeExisting:(BOOL)removeExisting
{
    NSString *pathToVirtualizedApplicationDirectory = [[options[PXVirtualizedApplicationLaunchPathKey] stringByDeletingLastPathComponent] stringByStandardizingPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToVirtualizedApplicationDirectory] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:pathToVirtualizedApplicationDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }

    if (removeExisting == YES) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToVirtualizedApplicationDirectory error:nil];
    }
    
    for (NSString *fileItemName in self.itemsToVirtualize) {
        [[NSFileManager defaultManager] createSymbolicLinkAtPath:[pathToVirtualizedApplicationDirectory stringByAppendingPathComponent:fileItemName]
                                             withDestinationPath:[self.installPath stringByAppendingPathComponent:fileItemName]
                                                           error:nil];
    }
    for (NSString *fileItemName in self.itemsToCopy) {
        NSString *destinationPath = [pathToVirtualizedApplicationDirectory stringByAppendingPathComponent:fileItemName];
        
        [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:nil];
        [[NSFileManager defaultManager] copyItemAtPath:[self.installPath stringByAppendingPathComponent:fileItemName]
                                                toPath:destinationPath
                                                 error:nil];
    }
}


#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder
{
    NSString *applicationName = [decoder decodeObjectForKey:PXApplicationDisplayNameKey];
    
    for (PXApplication *application in [PXApplication supportedApplications]) {
        if ([application.displayName isEqualToString:applicationName] == YES) {
            return application;
        }
    }
    
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.displayName forKey:PXApplicationDisplayNameKey];
}


@end
