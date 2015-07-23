//
//  SymbolicateCrashHelper.h
//  VisualSymbolicateCrash
//
//  Created by ximiao on 15/6/2.
//  Copyright (c) 2015年 ximiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyDragingFileView.h"

@interface SymbolicateCrashHelper : NSObject
+ (void)registCommandLineShortCut:(NSString*)shortCutName;
+ (void)SaveFile:(MyFileInfo*)file;
@end
