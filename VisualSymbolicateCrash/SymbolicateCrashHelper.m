//
//  SymbolicateCrashHelper.m
//  VisualSymbolicateCrash
//
//  Created by ximiao on 15/6/2.
//  Copyright (c) 2015年 ximiao. All rights reserved.
//

#import "SymbolicateCrashHelper.h"
@implementation SymbolicateCrashHelper
//创建命令行超链接，使访问地址变短
+ (void)registCommandLineShortCut:(NSString*)shortCutName {
    NSMutableString *cmd = [[NSMutableString alloc] initWithString:@"$ ln -s "];
    [cmd appendString:[self getSymbolicateCrashCommandLine]];
    [cmd appendString:@" /usr/bin/"];
    [cmd appendString:shortCutName];
    [self runCommandLine:cmd Args:nil];
}

//------------------------------------------------------
+ (void)SaveFile:(MyFileInfo*)file {
    if ([file.ext isEqualToString:@"dSYM"]) {
        [self SaveDSYMFile:file];
    } else if ([file.ext isEqualToString:@"crash"]) {
        [self SaveCrashFile:file];
    } else if ([file.ext isEqualToString:@"ipa"]) {
        [self SaveIPAFile:file];
    }
}
+ (void)SaveDSYMFile:(MyFileInfo*)file {
    NSArray* uuids = [self getGUID_DSYM:file];
    for (NSString *uuid in uuids) {
        NSString *savePath = [self getPathWithGUID:uuid];
        [self copyFile:file ToPath:savePath];
    }
}
+ (void)SaveCrashFile:(MyFileInfo*)file {
    NSString *uuid = [self getGUID_Crash:file];
    NSString *savePath = [self getPathWithGUID:uuid];
    [self copyFile:file ToPath:savePath];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    for (NSString *fileName in [manager enumeratorAtPath:savePath]) {
        if ([[fileName pathExtension] isEqualTo:@"dSYM"]) {
            NSString *cmd = [self getSymbolicateCrashCommandLine];
            NSMutableArray *args = [[NSMutableArray alloc] init];
            [args addObject:file.fullPath];
            NSString *dSYMPath = [NSString stringWithFormat:@"%@/%@", savePath, fileName];
            [args addObject:dSYMPath];
            //[args addObject:@">"];
            NSString *outputPath = [NSString stringWithFormat:@"%@/%@.txt", savePath, file.name];
            //[args addObject:outputPath];
            NSString* text = [self runCommandLine:cmd Args:args];
            __autoreleasing NSError *error = [[NSError alloc] init];
            [text writeToFile:outputPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            
            cmd = @"/usr/bin/open";
            [args removeAllObjects];
            [args addObject:outputPath];
            [self runCommandLine:cmd Args:args];
            break;
        }
    }
}
+ (void)SaveIPAFile:(MyFileInfo*)file {
    MyFileInfo*appFile = [[MyFileInfo alloc] initWithFullPath:[self getAppFromIPA:file]];
    NSArray *uuids = [self getGUID_APP:appFile];
    for (NSString *uuid in uuids) {
        NSString *savePath = [self getPathWithGUID:uuid];
        [self copyFile:appFile ToPath:savePath];
        [self copyFile:file ToPath:savePath];
    }
}

+ (NSString*)getAppFromIPA:(MyFileInfo*)file {
    NSString *cmd1 =@"/bin/rm";
    NSMutableArray *args = [[NSMutableArray alloc] init];
    [args addObject:@"-r"];
    [args addObject:[NSString stringWithFormat:@"%@/PayLoad", [self getCachePath]]];
    [self runCommandLine:cmd1 Args:args];
    
    NSMutableString *str = [[NSMutableString alloc] initWithString:[self getCachePath]];
    //[str appendFormat:@"/%@",file.name];
    [args removeAllObjects];
    [args addObject:@"-q"];
    [args addObject:file.fullPath];
    [args addObject:@"-d"];
    [args addObject:str];
    NSString *cmd = @"/usr/bin/unzip";
    NSString *ret = [self runCommandLine:cmd Args:args];
    [str appendString:@"/Payload/WeiboMovie.app"];
    return str;
}
+ (NSArray*)getGUID_DSYM:(MyFileInfo*)file {
    NSString *cmd = @"/usr/bin/dwarfdump";
    NSMutableArray *args = [[NSMutableArray alloc] init];
    [args addObject:@"--uuid"];
    [args addObject:[NSString stringWithFormat:@"%@/Contents/Resources/DWARF/WeiboMovie", file.fullPath]];
    NSString *uuid = [self runCommandLine:cmd Args:args];
    return [self getUUIDs:uuid];
}
+ (NSString*)getGUID_Crash:(MyFileInfo*)file {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:file.fullPath];
    NSData *data = [fileHandle readDataToEndOfFile];
    NSString *text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSRange range = [text rangeOfString:@"Binary Images:"];
    text = [text substringFromIndex:range.location];
    range = [text rangeOfString:@"<"];
    range.location += 1;
    range.length = 32;
    NSString *uuid = [text substringWithRange:range];
    uuid = [uuid uppercaseString];
    NSMutableString *mutableStr = [uuid mutableCopy];
    [mutableStr insertString:@"-" atIndex:8];
    [mutableStr insertString:@"-" atIndex:13];
    [mutableStr insertString:@"-" atIndex:18];
    [mutableStr insertString:@"-" atIndex:23];
    return mutableStr;
}
+ (NSArray*)getGUID_APP:(MyFileInfo*)file {
    NSString *cmd = @"/usr/bin/dwarfdump";
    NSMutableArray *args = [[NSMutableArray alloc] init];
    [args addObject:@"--uuid"];
    [args addObject:[NSString stringWithFormat:@"%@/WeiboMovie", file.fullPath]];
    NSString *uuid = [self runCommandLine:cmd Args:args];
    return [self getUUIDs:uuid];
}
+ (NSArray*)getUUIDs:(NSString*)idsStr {
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    NSMutableString *str = [idsStr mutableCopy];
    while (str.length > 0) {
        NSRange range = [str rangeOfString:@"UUID: "];
        if (range.length > 0) {
            NSString *uuid = [str substringWithRange:NSMakeRange(range.location + range.length, 36)];
            [ids addObject:uuid];
            [str deleteCharactersInRange:NSMakeRange(0, 42)];
        } else {
            break;
        }
    }
    return ids;
}

//-------------------------Tool---------------------------------
+ (NSString*)getPathWithGUID:(NSString*)guid {
    NSString *path = [NSString stringWithFormat:@"%@/%@", [self getAppPath], guid];
    return path;
}
+ (void)copyFile:(MyFileInfo*)file ToPath:(NSString*)path {
    NSString *cmd1 = @"/bin/mkdir";
    NSMutableArray *args1 = [[NSMutableArray alloc] init];
    [args1 addObject:path];
    [self runCommandLine:cmd1 Args:args1];
    
    NSString *cmd = @"/bin/cp";
    NSMutableArray *args = [[NSMutableArray alloc] init];
    [args addObject:@"-r"];
    [args addObject:@"-f"];
    [args addObject:file.fullPath];
    [args addObject:[NSString stringWithFormat:@"%@/%@.%@", path, file.name, file.ext]];
    [self runCommandLine:cmd Args:args];
}
+ (NSString*)getAppPath {
    NSString *path = [[NSBundle mainBundle] bundlePath];
    //NSRange range = [path rangeOfString:@"/" options:NSBackwardsSearch];
    //path = [path substringToIndex:range.location];
    return path;
}
+ (NSString*)getCachePath {
    return [NSString stringWithFormat:@"%@/Cache", [self getAppPath]];
}

//获取SymbolicateCrash命令行地址
+ (NSString*)getSymbolicateCrashCommandLine {
    return @"/Applications/Xcode.app/Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash";
}

+ (NSString*)runCommandLine2:(NSString*)cmd Args:(NSArray*)args {
    //int pid = [[NSProcessInfo processInfo] processIdentifier];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = cmd;
    if (args) {
        task.arguments = args;
    } else {
        task.arguments = [[NSArray alloc] init];
    }
    task.standardOutput = pipe;
    task.environment = [NSDictionary dictionaryWithObject:@"/Applications/XCode.app/Contents/Developer" forKey:@"DEVELOPER_DIR"];
    
    NSPipe *ePipe = [NSPipe pipe];
    NSFileHandle *eFile = ePipe.fileHandleForReading;
    task.standardError = ePipe;
    
    [task launch];
    
    NSString *temp = [[NSString alloc] initWithData: [eFile readDataToEndOfFile] encoding: NSUTF8StringEncoding];
    temp = [[NSString alloc] initWithData: [file readDataToEndOfFile] encoding: NSUTF8StringEncoding];
    //[task waitUntilExit];
    int status = [task terminationStatus];
    if (status == 0) {
        NSLog(@"Task succeeded.");
    }
    else {
        NSLog(@"Task failed.");
        NSData *eData = [eFile readDataToEndOfFile];
        [eFile closeFile];
        NSString *errorMsg = [[NSString alloc] initWithData:eData encoding: NSUTF8StringEncoding];
    }
    //[NSThread sleepForTimeInterval:2000];
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"grep returned:\n%@", grepOutput);
    return grepOutput;
}
+ (NSString*)runCommandLine:(NSString*)cmd Args:(NSArray*)args {
    //int pid = [[NSProcessInfo processInfo] processIdentifier];
    NSPipe *pipe = [NSPipe pipe];
    NSPipe *ePipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    task.standardOutput = pipe;
    task.standardError = ePipe;
    task.launchPath = cmd;
    if (args) {
        task.arguments = args;
    } else {
        task.arguments = [[NSArray alloc] init];
    }
    task.environment = [NSDictionary dictionaryWithObject:@"/Applications/XCode.app/Contents/Developer" forKey:@"DEVELOPER_DIR"];
    
    [task launch];
//    NSString *temp = [[NSString alloc] initWithData: [eFile readDataToEndOfFile] encoding: NSUTF8StringEncoding];
//    temp = [[NSString alloc] initWithData: [file readDataToEndOfFile] encoding: NSUTF8StringEncoding];
    [task waitUntilExit];
    int status = [task terminationStatus];
    if (status == 0) {
        NSLog(@"Task succeeded.");
    }
    else {
        NSLog(@"Task failed.");
        NSFileHandle *eFile = ePipe.fileHandleForReading;
        NSData *eData = [eFile readDataToEndOfFile];
        [eFile closeFile];
        NSString *errorMsg = [[NSString alloc] initWithData:eData encoding: NSUTF8StringEncoding];
    }
    NSFileHandle *file = pipe.fileHandleForReading;
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"grep returned:\n%@", grepOutput);
    return grepOutput;
}
@end
