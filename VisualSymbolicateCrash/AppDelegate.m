//
//  AppDelegate.m
//  VisualSymbolicateCrash
//
//  Created by ximiao on 15/6/2.
//  Copyright (c) 2015年 ximiao. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationWillTerminate" object:nil];
}

@end
