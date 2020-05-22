//
//  NSArray+Net_Ext.m
//  TYNetworkKit_Example
//
//  Created by tangyj on 2019/1/15.
//  Copyright © 2019 fengzhiku@126.com. All rights reserved.
//

#import "NSArray+Net_Ext.h"

@implementation NSArray (Net_Ext)

- (NSArray *)net_sortASCByASCII{
    
    
    NSStringCompareOptions comparisonOptions =NSNumericSearch|
    NSWidthInsensitiveSearch|NSForcedOrderingSearch;
    
    NSComparator sort = ^(NSString *obj1,NSString *obj2){
        
        NSRange range = NSMakeRange(0,obj1.length);
        
        return [obj1 compare:obj2 options:comparisonOptions range:range];
        
    };
    return [self sortedArrayUsingComparator:sort];
    
}

- (NSArray *)net_sortDESCByASCII{
    
    
    NSStringCompareOptions comparisonOptions =NSCaseInsensitiveSearch|NSNumericSearch|NSWidthInsensitiveSearch|NSForcedOrderingSearch;
    
    NSComparator sort = ^(NSString *obj2,NSString *obj1){
        
        NSRange range = NSMakeRange(0,obj1.length);
        
        return [obj1 compare:obj2 options:comparisonOptions range:range];
        
    };
    return [self sortedArrayUsingComparator:sort];
    
}

@end
