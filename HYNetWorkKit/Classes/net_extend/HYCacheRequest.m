//
//  HYCacheRequest.m
//  HYBaseModule_Example
//
//  Created by tangyj on 2019/6/4.
//  Copyright © 2019 fengzhiku@126.com. All rights reserved.
//

#import "HYCacheRequest.h"
#import "HYCacheManager.h"

@implementation HYCacheRequest

- (void)save
{
    if (self.result) {
        [HYCacheManagerInstance cacheObjct:self key:self.path];
    }
}

+ (instancetype)cacheFromPath:(NSString *)path
{
    id result = [HYCacheManagerInstance getCacheWithKey:path];
    if (result) {
        HYCacheRequest *req = result;
        return req;
    }
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.path forKey:@"path"];
    [aCoder encodeObject:self.result forKey:@"result"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder{ // NS_DESIGNATED_INITIALIZER
    if (self = [super init]) {
        self.path = [aDecoder decodeObjectForKey:@"path"];
        self.result = [aDecoder decodeObjectForKey:@"result"];
    }
    return self;
}
@end
