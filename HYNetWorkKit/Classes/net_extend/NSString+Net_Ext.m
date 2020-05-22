//
//  NSString+Net_Ext.m
//  TYNetworkKit_Example
//
//  Created by tangyj on 2019/1/15.
//  Copyright © 2019 fengzhiku@126.com. All rights reserved.
//

#import "NSString+Net_Ext.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Net_Ext)

- (id)net_objectFromJSONString {
    @try {
        
        NSError * err ;
        
        id sender = [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&err];
        
//        if (err) {
//            NSError * error ;
//            NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
//
//
//            sender = [data jk_objectFromJSONDataWithParseOptions:JKParseOptionLooseUnicode error:&error];   // use JSONKit
//            if (!error) {
//                return sender;
//            }
//            return @"";
//        }else{
            return sender;
//        }
    
    }
    @catch (NSException *exception) {
        return @"";
    }
}

- (NSString *) net_md5{
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return  output;
}

@end
