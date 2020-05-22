//
//  HYCacheRequest.h
//  HYBaseModule_Example
//
//  Created by tangyj on 2019/6/4.
//  Copyright © 2019 fengzhiku@126.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYCacheRequest : NSObject<NSCoding>

@property (nonatomic,strong)NSString *path;//缓存路径
@property (nonatomic,strong)id result;// 缓存网络结果

// 缓存网络请求
- (void)save;

// 获取缓存网络请求
+ (instancetype)cacheFromPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
