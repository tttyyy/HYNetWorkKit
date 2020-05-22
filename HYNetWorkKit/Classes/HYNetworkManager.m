//
//  HYNetworkManager.m
//  TYNetworkKit_Example
//
//  Created by tangyj on 2019/1/15.
//  Copyright © 2019 fengzhiku@126.com. All rights reserved.
//

#import "HYNetworkManager.h"
#import "NSArray+Net_Ext.h"
#import "NSString+Net_Ext.h"
#import "HYCacheRequest.h"

#define KEY_SIGN       @"sign"

#define KTokenKey      @"token"

@interface HYNetworkManager()
@property (nonatomic, strong) NSString * host;
@property (nonatomic, strong) NSString * apiPath;
@property (nonatomic, assign) BOOL apiCacheWhenFailed;

@property (nonatomic, strong) NSDictionary * paramDic;
@property (nonatomic,   copy) void (^successBlock)(NSDictionary *);
@property (nonatomic,   copy) void (^failureBlock)(NSError *,NSInteger,NSString *);
@property (nonatomic,   copy) NetBlock progressBlock;

@end

@implementation HYNetworkManager

+(HYNetworkManager *)sharedHYNetworkManager {
    static dispatch_once_t onceToken;
    static HYNetworkManager * _instance;
    dispatch_once(&onceToken, ^{
        _instance = [[HYNetworkManager alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.status = AFNetworkReachabilityStatusUnknown;
        [self checkNetStatus];
    }
    return self;
}

////检测网络
-(void)checkNetStatus
{
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
    session.requestSerializer.timeoutInterval = 30.;//
    session.responseSerializer = [AFHTTPResponseSerializer serializer];
    [session.reachabilityManager startMonitoring];
    [session.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (self.status != status) {
            self.status = status;
        }
    }];
}

- (NSDictionary *)commonParam{
    NSDictionary *dic;
    if ([self.delegate respondsToSelector:@selector(networkManager_getCommonParam)]) {
        dic = [self.delegate networkManager_getCommonParam];
    }
    return dic;
}

- (AFHTTPSessionManager *)createSessionManager:(NSURL *)baseURL{
    if (!baseURL) {
        if (self.defaultHost.length == 0) {
            NSLog(@"没有目标IP并且没有默认IP");
            return nil;
        }else {
            baseURL = [NSURL URLWithString:self.defaultHost];
        }
    }
    
    static AFHTTPSessionManager *sessionManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
        sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        sessionManager.requestSerializer  = [AFHTTPRequestSerializer serializer];
        
        sessionManager.requestSerializer.timeoutInterval = 30;
        sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json", @"text/javascript",@"text/html",@"text/plain",@"application/x-www-form-urlencoded",@"multipart/form-data",nil];
        
        [sessionManager.requestSerializer setValue:@"multipart/form-data" forHTTPHeaderField:@"Accept-Encoding"];
        
        [sessionManager.requestSerializer setHTTPShouldHandleCookies:YES];
        sessionManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        
        sessionManager.securityPolicy.allowInvalidCertificates = YES;
        [sessionManager.securityPolicy setValidatesDomainName:NO];
    });
    
    
    NSData *Cookiedata = [[NSUserDefaults standardUserDefaults] objectForKey:KTokenKey];
    if (![self.apiPath hasSuffix:@"login"] && Cookiedata) {
        // 如果请求头里面没有cookie 添加进cookiestage里
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        if (storage.cookies.count == 0) {
            NSArray *cookies = nil;
            if ([Cookiedata isKindOfClass:[NSData class]]) {
                cookies = [NSKeyedUnarchiver unarchiveObjectWithData:Cookiedata];
            }
            for (NSHTTPCookie *cookie in cookies) {
                [storage setCookie:cookie];
            }
        }
    }
    if([self.apiPath hasSuffix:@"login"])
    {
        // 登录的时候 清除 cookie
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in [storage cookies]) {
            [storage deleteCookie:cookie];
        }
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:KTokenKey];
    }
    return sessionManager;
}


- (NSDictionary *)joinParam:(NSDictionary*)param{
    
    NSMutableDictionary * pDic = [NSMutableDictionary dictionaryWithDictionary:[self commonParam]];
    for (NSString * key in param) {
        [pDic setObject:param[key] forKey:key];
    }
    return pDic;
    
}

- (NSString *)sign:(NSDictionary *)dic{
    NSArray * ascAllKeys = dic.allKeys;
    
    NSMutableArray * paramArray = [NSMutableArray array];
    
    for (NSString * key in ascAllKeys) {
        [paramArray addObject:[NSString stringWithFormat:@"%@%@",key,dic[key]]];
    }
    
    paramArray = [paramArray net_sortASCByASCII].mutableCopy;
    
    [paramArray addObject:self.kAppSecret];
    
    NSString * param = [paramArray componentsJoinedByString:@""];
    
    return [param net_md5];
}

- (NSURLSessionTask *)httpMethod:(HTTPMETHOD)httpMethod
                       cacheTime:(NSTimeInterval)cacheTime
                            path:(NSString *)path
                           param:(NSDictionary*)param
                        progress:(void(^)(id responseObject))progress
                         success:(void(^)(id responseObject))success
                         failure:(void(^)(NSError * errorInfoString,NSInteger statusCode,NSString *_Nonnull errorString))failure{
    
    return [self httpMethod:httpMethod path:path param:param progress:progress success:success failure:failure];
    
}
- (NSURLSessionTask *)httpMethod:(HTTPMETHOD)httpMethod
                            path:(NSString *)path
                           param:(NSDictionary*)param
                        progress:(void(^)(id responseObject))progress
                         success:(void(^)(id _Nonnull responseObject))success
                         failure:(void(^)(NSError *_Nullable error,NSInteger statusCode,NSString *_Nonnull errorString))failure{
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] initWithDictionary:[self commonParam]];
    BOOL isCacheWhenFailed = self.apiCacheWhenFailed;
    
    for (NSString * key in param) {
        [dic setObject:param[key] forKey:key];
    }
    NSURL * baseURL;
    if (!Net_StringIsNullOrEmpty(self.host)) {
        baseURL = [NSURL URLWithString:self.host];
        self.host = nil;
    }else
    {
        if (!Net_StringIsNullOrEmpty(self.defaultHost)) {
            baseURL = [NSURL URLWithString:self.defaultHost];
        }else
        {
            baseURL = [NSURL URLWithString:HY_BASE_URL];
        }
    }
    void (^FAILURE)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull) = ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (isCacheWhenFailed) {
            HYCacheRequest *cacheReq =  [HYCacheRequest cacheFromPath:[NSString stringWithFormat:@"%@%@%@",baseURL.absoluteString,path,[[NSUserDefaults standardUserDefaults] objectForKey:@"__userId__"]]];
            if (cacheReq) {
                [self endSuccessWithBlock:success result:cacheReq.result];
                return;
            }
        }
        if (failure) {
            NSInteger statusCode = -1;
            NSString *errorInfoString = @"";
            if (self.status == AFNetworkReachabilityStatusNotReachable) {
                statusCode = -1009;
                failure(error,statusCode,[self checkError:statusCode instructionString:nil]);
                return;
            }
            if ([error.userInfo objectForKey:@"com.alamofire.serialization.response.error.data"]) {
                NSDictionary *errorInfoDic = [NSJSONSerialization JSONObjectWithData:[error.userInfo objectForKey:@"com.alamofire.serialization.response.error.data"] options:NSJSONReadingMutableLeaves error:NULL];
                if (errorInfoDic) {
                    if ([errorInfoDic objectForKey:@"status"]) {
                        statusCode = [[errorInfoDic objectForKey:@"status"] integerValue];
                    }else
                    {
                        statusCode = error.code;
                    }
                    errorInfoString = Net_StringIsNullRetString([errorInfoDic objectForKey:@"message"], [self checkError:statusCode instructionString:nil]);
                    failure(error,statusCode,errorInfoString);
                }else
                {
                    NSHTTPURLResponse *resp = [error.userInfo objectForKey:@"com.alamofire.serialization.response.error.response"];
                    if (resp) {
                        statusCode = [resp statusCode];
                    }else
                    {
                        statusCode = error.code;
                    }
                    errorInfoString = [self checkError:statusCode instructionString:nil];
                    failure(error,statusCode,errorInfoString);
                }
            }else
            {
                statusCode = error.code;
                failure(error,statusCode,[self checkError:statusCode instructionString:nil]);
            }
        }
    };
    void(^PROGRESS)(NSProgress * _Nonnull) = ^(NSProgress * _Nonnull pro) {
        if (progress) {
            progress(pro);
        }
    };
    
    void (^SUCCESS)(NSURLSessionDataTask * _Nonnull, id _Nullable) = ^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject) {
            id data = responseObject;//[result net_objectFromJSONString];
            if ([path hasSuffix:@"login"]) {
                // 登录成功 缓存cookie
                NSArray *cookies =  [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
                if (cookies && cookies.count) {
                    // 缓存cookie
                    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:cookies];
                    [[NSUserDefaults standardUserDefaults] setValue:cookieData forKey:KTokenKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
            if (self.apiCacheWhenFailed) {
                HYCacheRequest *cacheReq = [[HYCacheRequest alloc] init];
                cacheReq.path = [NSString stringWithFormat:@"%@%@%@",baseURL.absoluteString,path,[[NSUserDefaults standardUserDefaults] objectForKey:@"__userId__"]];
                cacheReq.result = data;
                [cacheReq save];
            }
            [self endSuccessWithBlock:success result:data];
        }else
        {
            if (success) {
                success(responseObject);
            }
        }
    };
    
    path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    if (httpMethod == HTTP_GET) {
        NSURLSessionTask * task = [[self createSessionManager:baseURL] GET:path
                                                                parameters:dic
                                                                  progress:NULL
                                                                   success:SUCCESS
                                                                   failure:FAILURE];
        
        return task;
    }else if(httpMethod == HTTP_POST_FILE){
        NSArray *filesArr = dic[@"files"];
        if (filesArr) {
            [dic removeObjectForKey:@"files"];
        }
        return  [[self createSessionManager:baseURL] POST:path parameters:dic constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            //        AttachItem
            if ([filesArr isKindOfClass:[NSArray class]]) {
                for (HYAttachItem *item in filesArr) {
                    NSString *mimeType;
                    NSString *fileType;
                    if (item.fileType == 0) {
                        mimeType = @"image/jpg";
                        fileType = @".jpg";
                    }else if (item.fileType == 1)
                    {
                        mimeType = @"audio/wav";
                        fileType = @".mp3";
                    }else if(item.fileType == 2)
                    {
                        mimeType = @"video/quicktime";
                        fileType = @".mp4";
                    }else
                    {
                        mimeType = @"application/pdf";
                        fileType = @".pdf";
                    }
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"yyyy-MM-ddHH:mm:ss"];
                    NSString *nowDate = [formatter stringFromDate:[NSDate date]];
                    
                    NSString *fileName = Net_StringIsNullRetString(item.fileName, @"attach");
                    
                    [formData appendPartWithFileData:item.fileData name:fileName fileName:[NSString stringWithFormat:@"%@%@%@",nowDate,fileName,fileType] mimeType:mimeType];
                }
            }
            
        } progress:PROGRESS success:SUCCESS failure:FAILURE];
    }
    else if (httpMethod == HTTP_DELETE)
    {
        NSURLSessionTask * task = [[self createSessionManager:baseURL] DELETE:path
                                                                   parameters:dic
                                                                      success:SUCCESS
                                                                      failure:FAILURE];
        return task;
    }else if (httpMethod == HTTP_PUT)
    {
        NSURLSessionTask * task = [[self createSessionManager:baseURL] PUT:path parameters:dic success:SUCCESS failure:FAILURE];
        return task;
    }
    else{
        NSURLSessionTask * task = [[self createSessionManager:baseURL] POST:path
                                                                 parameters:dic
                                                                   progress:NULL
                                                                    success:SUCCESS
                                                                    failure:FAILURE];
        return task;
    }
}

- (void)endSuccessWithBlock:(void (^)(id))success result:(id)data
{
    if (success) {
        if ([data isKindOfClass:[NSData class]]) {
            id rootDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:NULL];
            if (rootDic) {
                success(rootDic);
            }else
            {
                NSString*result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                success(result);
            }
        }else{
            success(data);
        }
    }
}

/**
 错误码处理
 
 @param code 错误码
 @param instruction 描述
 @return 错误描述
 */
- (NSString *)checkError:(NSInteger)code instructionString:(NSString *)instruction {
    NSString * errorInfoString = nil;
    if (code == 401) {
        errorInfoString = @"登录信息已失效";
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:KTokenKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:KHY_NOTIFICATION_RELOGIN object:nil];
    }else if (code == 403)
    {
        errorInfoString = @"禁止访问";
    }else if (code == 404)
    {
        errorInfoString = @"地址错误";
    }else if (code == -1009){//无网络连接
        errorInfoString = @"请检查网络是否正常";
    }
    else if (code == -1004){
        errorInfoString = @"未能连接到服务器";
    }
    else if (code == -1001){//网络请求超时
        errorInfoString = @"请检查网络是否正常";
    }
    else
    {
        errorInfoString = @"请求异常";
    }
    return errorInfoString;
    
}

@end


@implementation HYNetworkManager (Custom)

- (HYNetworkManager *(^)(NSString *))path{
    return ^HYNetworkManager *(NSString * path){
        self.apiPath = path;
        return self;
    };
}
- (HYNetworkManager * (^)(NSDictionary *))param{
    return ^HYNetworkManager *(NSDictionary *param){
        self.paramDic = param;
        return self;
    };
}
- (HYNetworkManager * (^)(NSString *))baseURL{
    return ^HYNetworkManager *(NSString *baseURL){
        self.host = baseURL;
        return self;
    };
}

- (HYNetworkManager *(^)(BOOL))cacheWhenFailed
{
    return ^HYNetworkManager *(BOOL apiCacheWhenFailed){
        self.apiCacheWhenFailed = apiCacheWhenFailed;
        return self;
    };
}

- (HYNetworkManager * (^)(NetBlock))progress{
    return ^HYNetworkManager *(NetBlock progress){
        self.progressBlock = progress;
        return self;
    };
}
- (HYNetworkManager * (^)(NetBlock))success{
    return ^HYNetworkManager *(NetBlock success){
        self.successBlock = success;
        return self;
    };
}
- (HYNetworkManager * (^)(void (^)(NSError *,NSInteger,NSString *)))failure{
    return ^HYNetworkManager *(void(^failure)(NSError *,NSInteger,NSString *)){
        self.failureBlock = failure;
        return self;
    };
    
}
- (NSURLSessionTask *)POST{
    void(^tmpSuccessBlock)(id) = self.successBlock;
    void(^tmpFailureBlock)(NSError *,NSInteger,NSString *) = self.failureBlock;
    NetBlock tmpProgressBlock = self.progressBlock;
    
    NSURLSessionTask * task = [self httpMethod:HTTP_POST path:self.apiPath param:self.paramDic progress:tmpProgressBlock success:tmpSuccessBlock failure:tmpFailureBlock];
    //    self.cacheOutTime = 0;
    self.host = nil;
    self.apiPath = nil;
    self.paramDic = nil;
    self.successBlock = nil;
    self.failureBlock = nil;
    self.progressBlock = nil;
    self.apiCacheWhenFailed = NO;
    return task;
}
- (NSURLSessionTask *)GET{
    void(^tmpSuccessBlock)(id) = self.successBlock;
    void(^tmpFailureBlock)(NSError *,NSInteger,NSString *) = self.failureBlock;
    NSURLSessionTask * task = [self httpMethod:HTTP_GET path:self.apiPath param:self.paramDic progress:nil success:tmpSuccessBlock failure:tmpFailureBlock];
    self.host = nil;
    self.apiPath = nil;
    self.paramDic = nil;
    self.successBlock = nil;
    self.failureBlock = nil;
    self.apiCacheWhenFailed = NO;
    return task;
}

- (NSURLSessionTask *)POSTFile{
    void(^tmpSuccessBlock)(id) = self.successBlock;
    void(^tmpFailureBlock)(NSError *,NSInteger,NSString *) = self.failureBlock;
    NetBlock tmpProgressBlock = self.progressBlock;
    
    NSURLSessionTask * task = [self httpMethod:HTTP_POST_FILE path:self.apiPath param:self.paramDic progress:tmpProgressBlock success:tmpSuccessBlock failure:tmpFailureBlock];
    self.host = nil;
    self.apiPath = nil;
    self.paramDic = nil;
    self.successBlock = nil;
    self.failureBlock = nil;
    self.progressBlock = nil;
    self.apiCacheWhenFailed = NO;
    return task;
}

- (NSURLSessionTask *)DELETE
{
    void(^tmpSuccessBlock)(id) = self.successBlock;
    void(^tmpFailureBlock)(NSError *,NSInteger,NSString *) = self.failureBlock;
    NetBlock tmpProgressBlock = self.progressBlock;
    
    NSURLSessionTask * task = [self httpMethod:HTTP_DELETE path:self.apiPath param:self.paramDic progress:tmpProgressBlock success:tmpSuccessBlock failure:tmpFailureBlock];
    self.host = nil;
    self.apiPath = nil;
    self.paramDic = nil;
    self.successBlock = nil;
    self.failureBlock = nil;
    self.progressBlock = nil;
    self.apiCacheWhenFailed = NO;
    return task;
}

- (NSURLSessionTask *_Nullable)PUT
{
    void(^tmpSuccessBlock)(id) = self.successBlock;
    void(^tmpFailureBlock)(NSError *,NSInteger,NSString *) = self.failureBlock;
    NetBlock tmpProgressBlock = self.progressBlock;
    
    NSURLSessionTask * task = [self httpMethod:HTTP_PUT path:self.apiPath param:self.paramDic progress:tmpProgressBlock success:tmpSuccessBlock failure:tmpFailureBlock];
    self.host = nil;
    self.apiPath = nil;
    self.paramDic = nil;
    self.successBlock = nil;
    self.failureBlock = nil;
    self.progressBlock = nil;
    self.apiCacheWhenFailed = NO;
    return task;
}

- (NSURLSessionTask *)POST_LOG{
    NSString * url = self.logHost;
    if (Net_StringNotNullAndEmpty(self.host)) {
        url = self.host;
    }
    void(^tmpSuccessBlock)(id) = self.successBlock;
    void(^tmpFailureBlock)(NSError *,NSInteger,NSString *) = self.failureBlock;
    void (^SUCCESS)(NSURLSessionDataTask * _Nonnull, id _Nullable) = ^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (tmpSuccessBlock) {
            tmpSuccessBlock(responseObject);
        }
    };
    void (^FAILURE)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull) = ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (tmpFailureBlock) {
            tmpFailureBlock(error,error.code,error.domain);
        }
    };
    
    
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    
    
    NSURLSessionDataTask *task =  [sessionManager POST:self.logHost
                                            parameters:self.paramDic
                                              progress:NULL
                                               success:SUCCESS
                                               failure:FAILURE];
    self.host = nil;
    self.apiPath = nil;
    self.paramDic = nil;
    self.successBlock = nil;
    self.failureBlock = nil;
    return task;
}

@end
