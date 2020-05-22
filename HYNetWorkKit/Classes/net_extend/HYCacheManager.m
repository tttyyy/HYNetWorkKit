//
//  HYCacheManager.m
//  HYBaseModule_Example
//
//  Created by tangyj on 2019/6/4.
//  Copyright © 2019 fengzhiku@126.com. All rights reserved.
//

#import "HYCacheManager.h"
#import "NSString+Net_Ext.h"
@interface HYCacheManager()

@property (nonatomic,strong)NSCache *cache;

@end

@implementation HYCacheManager


+ (instancetype)sharedInstance
{
    static HYCacheManager *sharedInstace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstace = [[super allocWithZone:NULL] init];
        sharedInstace.cache = [[NSCache alloc] init];
    });
    return sharedInstace;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [HYCacheManager sharedInstance];
}

- (void)cacheObjct:(id)object key:(NSString *)key
{
    if (!object || Net_StringIsNullOrEmpty(key)) {
        return;
    }
    [self.cache setObject:object forKey:key];
    
    dispatch_queue_t myQueue = dispatch_queue_create("com.hycloud.myCustomQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(myQueue, ^{
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:object] forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

- (id)getCacheWithKey:(NSString *)key
{
    id object = [self.cache objectForKey:key];
    if (!object) {
        object = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:key]];
    }
    return object;
}

@end
