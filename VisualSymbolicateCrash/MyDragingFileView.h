//
//  MyDragingFileView.h
//  VisualSymbolicateCrash
//
//  Created by ximiao on 15/6/2.
//  Copyright (c) 2015年 ximiao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MyFileInfo : NSObject
- (id)initWithFullPath:(NSString*)path;
@property (nonatomic, strong)NSString *name;
@property (nonatomic, strong)NSString *ext;
@property (nonatomic, strong)NSString *fullPath;
@end

@protocol MyDragingFileDelegate <NSObject>
- (NSDragOperation)onDragEnter:(NSArray*)files;
- (void)onDrop:(NSArray*)files;
@end

@interface MyDragingFileView : NSView
@property (nonatomic, weak)id<MyDragingFileDelegate> delegate;
@end
