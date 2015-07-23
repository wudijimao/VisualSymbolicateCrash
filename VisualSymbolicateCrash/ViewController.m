//
//  ViewController.m
//  VisualSymbolicateCrash
//
//  Created by ximiao on 15/6/2.
//  Copyright (c) 2015年 ximiao. All rights reserved.
//

#import "ViewController.h"
#import "MyDragingFileView.h"
#import "SymbolicateCrashHelper.h"

#import "DTLog.h"

typedef SymbolicateCrashHelper Helper;

@interface ViewController()<MyDragingFileDelegate> {
}
@property (weak) IBOutlet NSTextField *label;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    MyDragingFileView *dropView = (MyDragingFileView*)self.view;
    dropView.delegate = self;
    self.label.stringValue = @"拖动crash、dSYM、IPA文件到此";
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (NSDragOperation)onDragEnter:(NSArray*)files {
    BOOL hasCrashFile = NO;
    BOOL hasDSYMFile= NO;
    BOOL hasIPAFile = NO;
    for (MyFileInfo *file in files) {
        NSLog(@"FileName:%@,Num:%ld", file.name, files.count);
        if ([file.ext isEqualToString:@"dSYM"]) {
            hasDSYMFile = YES;
        } else if ([file.ext isEqualToString:@"crash"]) {
            hasCrashFile = YES;
        } else if ([file.ext isEqualToString:@"ipa"]) {
            hasIPAFile = YES;
        }
    }
    if (hasCrashFile || hasDSYMFile || hasIPAFile) {
        self.label.stringValue = @"请松手以添加文件";
        return NSDragOperationMove;
    } else {
        return NSDragOperationNone;
    }
}
- (void)onDrop:(NSArray*)files {
    self.label.stringValue = @"拖动crash、dSYM、IPA文件到此";
    NSMutableArray *crashFiles = [[NSMutableArray alloc] init];
    for (MyFileInfo *file in files) {
        if ([file.ext isEqualToString:@"dSYM"]) {
            [Helper SaveFile:file];
        } else if ([file.ext isEqualToString:@"crash"]) {
            [crashFiles addObject:file];
        } else if ([file.ext isEqualToString:@"ipa"]) {
            [Helper SaveFile:file];
        }
    }
    for (MyFileInfo *file in crashFiles) {
        [Helper SaveFile:file];
    }
}
@end
