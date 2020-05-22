//
//  HYCacheManager.h
//  HYBaseModule_Example
//
//  Created by tangyj on 2019/6/4.
//  Copyright © 2019 fengzhiku@126.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define HYCacheManagerInstance          [HYCacheManager sharedInstance]
@interface HYCacheManager : NSObject

+ (instancetype)sharedInstance;


- (void)cacheObjct:(id)object key:(NSString *)key;

- (id)getCacheWithKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
