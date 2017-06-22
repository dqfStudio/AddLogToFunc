//
//  AddLogToFunc.m
//  AddLogToFunc
//
//  Created by dqf on 2017/6/19.
//  Copyright © 2017年 DNE Technology Co.,Ltd. All rights reserved.
//

#import "AddLogToFunc.h"

@interface AddLogToFunc ()

@property (nonatomic, assign) BOOL keepOn;
@property (nonatomic, assign) BOOL skip;
@property (nonatomic, strong) NSMutableArray  *allCodeArr;
@property (nonatomic, strong) NSMutableString *mutableStr;

@end

@implementation AddLogToFunc

static NSMutableString *__text = nil;

- (NSMutableArray *)allCodeArr
{
    if (!_allCodeArr) {
        _allCodeArr = [NSMutableArray arrayWithCapacity:1];
    }
    return _allCodeArr;
}

- (NSMutableString *)mutableStr
{
    if (!_mutableStr) {
        _mutableStr = [[NSMutableString alloc] initWithString:@""];;
    }
    return _mutableStr;
}

+ (AddLogToFunc *)share {
    static dispatch_once_t predicate;
    static AddLogToFunc *sharedManager;
    dispatch_once(&predicate, ^{
        sharedManager=[[AddLogToFunc alloc] init];
    });
    return sharedManager;
}

+ (NSString *)openWithPath:(NSString *)path{
    
    __text = [NSMutableString string];

    NSFileManager *fileManage = [NSFileManager defaultManager];
    
    NSArray *files = [fileManage subpathsOfDirectoryAtPath: path error:nil];
    
    files = [self getClassPathInAry:files inPath:path];
    
    for(NSString *path in files){
        [[self share] checkFile:path];
    }
    
    return __text;
}


+ (NSArray *)getClassPathInAry:(NSArray *)ary inPath:(NSString *)inPath{
    NSMutableArray *pathArray = [NSMutableArray array];
    for(NSString *path in ary){
        NSString *fileType = [path pathExtension];
        if([fileType isEqualToString:@"h"]){
            
            NSFileManager *fileManager = [[NSFileManager alloc]init];
            NSString *file = [NSString stringWithFormat:@"%@.m",[inPath stringByAppendingPathComponent:[path stringByDeletingPathExtension]]];
            if ([fileManager fileExistsAtPath:file]) {
                //[pathArray addObject:[inPath stringByAppendingPathComponent:path]];
                [pathArray addObject:file];
            }
        }
    }
    return pathArray;
}

- (int)checkFile:(NSString *)path
{
    const char *filePath = [path UTF8String];
    //printf("＝＝＝＝%s", filepath);
    FILE *fp1;//定义文件流指针，用于打开读取的文件
    char textStr[10241];//定义一个字符串数组，用于存储读取的字符
    fp1 = fopen(filePath,"r");//只读方式打开文件a.txt
    if (self.allCodeArr.count > 0) [self.allCodeArr removeAllObjects];
    _keepOn = NO;
    while(fgets(textStr,10240,fp1)!=NULL)//逐行读取fp1所指向文件中的内容到text中
    {
        [self findMethod:textStr];
    }
    fclose(fp1);//关闭文件a.txt，有打开就要有关闭

    //给每个函数增加打印方法
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    NSData *data = [fileManager contentsAtPath:path];
    NSString *fileStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    for (int i=0; i<self.allCodeArr.count; i++) {
        
        NSString *tmpStr = self.allCodeArr[i];
        //打印方式一
        //NSString *tmpStr2 = @"NSLog(@\"%s:%d\t%s\n\",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, _cmd);";
        //打印方式二
        //NSString *tmpStr2 = @"fprintf(stderr,\"%s:%d\t%s\n\",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, _cmd);";
        //打印方式三
        NSString *tmpStr2 = @"NSLog(@\"\");";
        
        NSLog(@"%@",tmpStr);
    
        NSString *replaceStr = [NSString stringWithFormat:@"%@\n\t%@",tmpStr,tmpStr2];

        fileStr = [fileStr stringByReplacingOccurrencesOfString:tmpStr withString:replaceStr];
    }
    
    [fileStr writeToFile:path atomically:yearMask encoding:NSUTF8StringEncoding error:nil];
    
    return 0;
}

- (void)findMethod:(char *)text
{
    //1、获取一行代码
    //2、除开空格第一个字符是“-”或“+”，代表这是一个方法的开始
    //3、包含“(”和“)”
    //4、如果方法名字换行，
    //5、函数以"{"开始，"}"结尾
    
    //获取一行代码
    NSString *codeStr = [NSString stringWithCString:text encoding:NSUTF8StringEncoding];
    //除去空格字符串
    NSString *noSpaceStr = [[codeStr mutableCopy] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    //直接跳过@interface和@end中的检测
    if (noSpaceStr.length >= 4 && noSpaceStr.length < 10 ) {
        if ([[noSpaceStr substringToIndex:4] isEqualToString:@"@end"]) {
            _skip = NO;
            //换下一行
            return;
        }
        
    } else if (noSpaceStr.length >= 10 ) {
        
        if ([[noSpaceStr substringToIndex:10] isEqualToString:@"@interface"]) {
            _skip = YES;
        }
    }
    
    if (_skip) {
        //换下一行
        return;
    }
    
    //判断第一个字符是“-”或“+”
    NSString *firstStr = [noSpaceStr substringToIndex:1];
    
    if (!_keepOn) {
        
        if ([firstStr isEqualToString:@"-"] || [firstStr isEqualToString:@"+"]) {
            
            //判断是否包含“(”和“)”
            if ([noSpaceStr containsString:@"("] && [noSpaceStr containsString:@")"]) {
                
                //判断是否包含“{”
                if ([noSpaceStr containsString:@"{"]) {
                    
                    //获取"{"在整个文件中的坐标
                    NSRange range = [codeStr rangeOfString:@"{"];
                    //找出函数方法
                    NSString *replaceStr = [codeStr substringToIndex:range.location+range.length];
                    [self.allCodeArr addObject:replaceStr];
                    
                } else {
                    [self.mutableStr appendString:codeStr];
                    _keepOn = YES;
                }
                
                //换下一行
                return;
                
            }
            
        }
        
    } else {
        
        if ([firstStr isEqualToString:@"-"] || [firstStr isEqualToString:@"+"]) {
            
            //判断是否包含“(”和“)”
            if ([noSpaceStr containsString:@"("] && [noSpaceStr containsString:@")"]) {
                
                //判断是否包含“{”
                if ([noSpaceStr containsString:@"{"]) {
                    
                    //获取"{"在整个文件中的坐标
                    NSRange range = [codeStr rangeOfString:@"{"];
                    //找出函数方法
                    NSString *replaceStr = [codeStr substringToIndex:range.location+range.length];
                    [self.allCodeArr addObject:replaceStr];
                    
                    [self.mutableStr setString:@""];
                    
                    _keepOn = NO;
                    
                } else {
                    [self.mutableStr setString:codeStr];
                }
                
                //换下一行
                return;
                
            }
            
        }
        
        if ([codeStr containsString:@"{"]) {
            
            //获取"{"在整个文件中的坐标
            NSRange range = [codeStr rangeOfString:@"{"];
            //找出函数方法
            NSString *replaceStr = [codeStr substringToIndex:range.location+range.length];
            [self.mutableStr appendString:replaceStr];
            
            [self.allCodeArr addObject:[self.mutableStr mutableCopy]];
            [self.mutableStr setString:@""];
            
            _keepOn = NO;
            
        } else {
            [self.mutableStr appendString:codeStr];
        }
        
        //换下一行
        return;

    }
    
}

@end
