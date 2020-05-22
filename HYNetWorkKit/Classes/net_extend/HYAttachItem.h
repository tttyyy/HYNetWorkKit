//
//  HYAttachItem.h
//  HYBaseModule_Example
//
//  Created by tangyj on 2019/6/1.
//  Copyright © 2019 fengzhiku@126.com. All rights reserved.
//

#import <Foundation/Foundation.h>

// 上传文件model
typedef enum : NSUInteger {
    AttachFileTypeImg = 0,
    AttachFileTypeMp3,
    AttachFileTypeMp4,
    AttachFileTypePdf
} AttachFileType;

NS_ASSUME_NONNULL_BEGIN

@interface HYAttachItem : NSObject

@property (nonatomic,strong)NSString *fileName;
@property (nonatomic,assign)NSInteger fileType; // 0 图片  1 音频  2 视频 3 PDF
@property (nonatomic,strong)NSData *fileData;

@end

NS_ASSUME_NONNULL_END
