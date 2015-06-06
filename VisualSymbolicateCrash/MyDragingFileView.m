//
//  MyDragingFileView.m
//  VisualSymbolicateCrash
//
//  Created by ximiao on 15/6/2.
//  Copyright (c) 2015年 ximiao. All rights reserved.
//

#import "MyDragingFileView.h"

@implementation MyFileInfo
- (id)initWithFullPath:(NSString*)path {
    self = [super init];
    if (self) {
        _fullPath = path;
        NSRange range = [path rangeOfString:@"/" options:NSBackwardsSearch];
        if (range.length == 1) {
            _name = [path substringFromIndex:range.location + range.length];
            range = [_name rangeOfString:@"." options:NSBackwardsSearch];
            if (range.length == 1) {
                _ext = [_name substringFromIndex:range.location + range.length];
                _name = [_name substringToIndex:range.location];
            }
        }
    }
    return self;
}
@end

@implementation MyDragingFileView {
    BOOL canDrop;
    NSMutableArray *files;
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    canDrop = NO;
    files = [[NSMutableArray alloc] init];
    return self;
}
- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    canDrop = NO;
    files = [[NSMutableArray alloc] init];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    [files removeAllObjects];
    NSPasteboard *pboard;
    NSDragOperation operation = NSDragOperationNone;
    pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:NSFilenamesPboardType])
    {
        NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
        if (filenames && filenames.count > 0) {
            for (NSString*fullPath in filenames) {
                [files addObject:[[MyFileInfo alloc] initWithFullPath:fullPath]];
            }
            operation = [self.delegate onDragEnter:files];
        }
    }
    if (operation == NSDragOperationMove) {
        canDrop = YES;
    } else {
        canDrop = NO;
    }
    return operation;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    if(canDrop) {
        [self.delegate onDrop:files];
    }
}

@end
