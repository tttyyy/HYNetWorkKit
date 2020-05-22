//
//  HYNetworkManager.h
//  TYNetworkKit_Example
//
//  Created by tangyj on 2019/1/15.
//  Copyright © 2019 fengzhiku@126.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "HYAttachItem.h"

#define NetWorkInstance              [HYNetworkManager sharedHYNetworkManager]
#define KHY_NOTIFICATION_RELOGIN  @"HY_NOTIFICATION_RELOGIN" //token失效 发送通知 或者没有登录

// 主服务器
#define HY_BASE_URL           @"https://betademo.houyicloud.com/"
// 图片服务器
#define HY_BASE_UPLOAD_URL    @"https://betaupload.houyicloud.com/"

typedef enum{
    HTTP_GET,
    HTTP_POST,
    HTTP_POST_FILE,//上传文件
    HTTP_DELETE,
    HTTP_PUT
} HTTPMETHOD;

typedef void (^NetBlock)(id _Nullable);

@protocol NetManagerDelegate<NSObject>

@required

/**
 全局公共参数
 */
- (NSDictionary *_Nullable)networkManager_getCommonParam;
@end


//NS_ASSUME_NONNULL_BEGIN
@interface HYNetworkManager : NSObject

/**
 网络状态
 */
@property (nonatomic, assign) AFNetworkReachabilityStatus status;

/**
 默认的IP
 */
@property (nonatomic, strong) NSString * _Nullable defaultHost;
/**
 LogHost
 */
@property (nonatomic, strong) NSString * _Nullable logHost;
@property (nonatomic, assign) id<NetManagerDelegate> _Nullable delegate;
@property (nonatomic, strong) NSString * _Nullable kAppSecret;

+ (instancetype _Nonnull )sharedHYNetworkManager;

/**
 @param httpMethod GET/POST
 @param path API名称
 @param param 参数
 @param success 成功回调
 @param failure 失败回调
 @return DataTask
 */
- (NSURLSessionTask *_Nonnull)httpMethod:(HTTPMETHOD)httpMethod
                            path:(NSString * _Nonnull)path
                           param:(NSDictionary*_Nullable)param
                                progress:(nullable void(^)(id _Nullable responseObject))progress
                                 success:(void(^_Nonnull)(id _Nonnull responseObject))success
                                 failure:(void(^_Nonnull)(NSError *_Nonnull error,NSInteger statusCode,NSString *_Nonnull errorString))failure;

@end

NS_ASSUME_NONNULL_BEGIN
@interface HYNetworkManager (Custom)
// 是否失败的时候取缓存(YES 开启缓存失败时取缓存);
- (HYNetworkManager * (^)(BOOL))cacheWhenFailed;
- (HYNetworkManager * (^)(NSString *))path;
- (HYNetworkManager * (^)(NSDictionary *))param;
- (HYNetworkManager *(^)(NSString *))baseURL;
- (HYNetworkManager * (^)(void (^)(id responseObject)))success;
- (HYNetworkManager * (^)(void (^)(id responseObject)))progress;
- (HYNetworkManager * (^)(void (^)(NSError *,NSInteger statusCode,NSString *_Nonnull errorString)))failure;
- (NSURLSessionTask *_Nullable )POST;
- (NSURLSessionTask *_Nullable )GET;
- (NSURLSessionTask *_Nullable)POSTFile;
- (NSURLSessionTask *_Nullable)DELETE;
- (NSURLSessionTask *_Nullable)PUT;


@end

NS_ASSUME_NONNULL_END
