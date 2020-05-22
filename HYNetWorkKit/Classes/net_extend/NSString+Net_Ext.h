//
//  NSString+Net_Ext.h
//  TYNetworkKit_Example
//
//  Created by tangyj on 2019/1/15.
//  Copyright © 2019 fengzhiku@126.com. All rights reserved.
//

#import <Foundation/Foundation.h>


UIKIT_STATIC_INLINE BOOL Net_StringIsNullOrEmpty(NSString* str)
{
    return ((NSNull *)str==[NSNull null] || str==nil||[str isEqualToString:@""]);
}

UIKIT_STATIC_INLINE BOOL Net_StringNotNullAndEmpty(NSString* str)
{
    return ((NSNull *)str!=[NSNull null] && str!=nil&&![str isEqualToString:@""]);
}

UIKIT_STATIC_INLINE NSString * Net_StringIsNullRetBlank(NSString *str){
    if (str==nil || (NSNull *)(str)==[NSNull null]) {
        return @"";
    }
    return  str;
}

UIKIT_STATIC_INLINE NSString * Net_StringIsNullRetString(NSString *str,NSString * repString){
    
    
    if (str==nil || (NSNull *)(str)==[NSNull null]||[str isEqualToString:@""]) {
        if (repString==nil || (NSNull *)(repString)==[NSNull null]||[repString isEqualToString:@""]) {
            return @"";
        }
        return repString;
    }
    return  str;
}

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Net_Ext)

- (id)net_objectFromJSONString;
- (NSString *) net_md5;

@end

NS_ASSUME_NONNULL_END
