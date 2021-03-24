//
//  HY_NetworkManager.m
//  HY_Networking_Example
//
//  Created by 猫态科技 on 2021/3/19.
//  Copyright © 2021 Baffin-HSL. All rights reserved.
//

#import "HY_NetworkManager.h"

@interface HY_NetworkManager ()

@property (nonatomic, strong) NSMutableArray *sessionTaskArray;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, assign) HY_NetworkStatus networkStatus;
@property (nonatomic,strong) NSDictionary *publicParams;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (copy) void (^globalConfigBlock)(AFHTTPSessionManager *sessionManager);

@end

@implementation HY_NetworkManager

+ (instancetype)sharedManager {
    static HY_NetworkManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HY_NetworkManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionTaskArray = [[NSMutableArray alloc] init];
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.securityPolicy = [AFSecurityPolicy defaultPolicy];
        _sessionManager.securityPolicy.allowInvalidCertificates = YES;
        _sessionManager.securityPolicy.validatesDomainName = NO;
        _sessionManager.requestSerializer.timeoutInterval = 30.0f;
        _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/plain", @"text/html", nil];
        _queue = dispatch_queue_create("com.wenqunxiang.HY_tools.queue", DISPATCH_QUEUE_CONCURRENT);
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    }
    return self;
}

/** 在这里进行网络请求的全局配置，每次发送请求都会调用该block */
+ (void)globalConfigWithBlock:(nullable void(^)(AFHTTPSessionManager *sessionManager))completion {
    [HY_NetworkManager sharedManager].globalConfigBlock = completion;
}

+ (void)setPublicParams:(NSMutableDictionary *)publicParams{
    [HY_NetworkManager sharedManager].publicParams = publicParams;
    
}

/** 开始监听网络状态，一旦状态发生变化，将会通过block返回 */
+ (void)startMonitoringNetworkStatusWithBlock:(nullable HY_NetworkStatusBlock)block {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusUnknown: {
                    [HY_NetworkManager sharedManager].networkStatus = HY_NetworkStatusUnknown;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block ? block(HY_NetworkStatusUnknown) : nil;
                    });
                    break;
                }
                case AFNetworkReachabilityStatusNotReachable: {
                    [HY_NetworkManager sharedManager].networkStatus = HY_NetworkStatusNotReachable;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block ? block(HY_NetworkStatusNotReachable) : nil;
                    });
                    break;
                }
                case AFNetworkReachabilityStatusReachableViaWWAN: {
                    [HY_NetworkManager sharedManager].networkStatus = HY_NetworkStatusReachableViaWWAN;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block ? block(HY_NetworkStatusReachableViaWWAN) : nil;
                    });
                    break;
                }
                case AFNetworkReachabilityStatusReachableViaWiFi: {
                    [HY_NetworkManager sharedManager].networkStatus = HY_NetworkStatusReachableViaWiFi;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block ? block(HY_NetworkStatusReachableViaWiFi) : nil;
                    });
                    break;
                }

                default:
                    break;
            }
#ifdef DEBUG
            if (status == AFNetworkReachabilityStatusUnknown) {
                NSLog(@"当前网络状态：未知网络");
            }else if (status == AFNetworkReachabilityStatusNotReachable) {
                NSLog(@"当前网络状态：无网络");
            }else if (status == AFNetworkReachabilityStatusReachableViaWWAN) {
                NSLog(@"当前网络状态：运营商网络");
            }else if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
                NSLog(@"当前网络状态：Wi-Fi网络");
            }
#endif
        }];
        [manager startMonitoring];
    });
}

/** 当前网络状态，默认为HY_NetworkStatusUnknown，调用方法后可获取真实值：startMonitoringNetworkStatus: */
+ (HY_NetworkStatus)getNetworkStatus {
    return [HY_NetworkManager sharedManager].networkStatus;
}

/**
 GET请求

 @param path        请求路径或者请求完整URL字符串
 @param parameters  请求参数
 @param success     请求成功的回调
 @param failure     请求失败的回调
 @return 返回的对象可取消请求，调用cancelRequestWithTask:方法
 */
+ (NSURLSessionTask *)GET:(nullable NSString *)path
                   parameters:(nullable id)parameters
                      success:(nullable HY_RequestSuccessBlock)success
                      failure:(nullable HY_RequestFailedBlock)failure {
    if ([HY_NetworkManager sharedManager].globalConfigBlock) {
        [HY_NetworkManager sharedManager].globalConfigBlock([HY_NetworkManager sharedManager].sessionManager);
    }
    if (path) {
        path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    }
    parameters = [self disposePublicParameters:parameters];//公共参数添加
    NSURLSessionTask *sessionTask = [[HY_NetworkManager sharedManager].sessionManager GET:path parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[HY_NetworkManager sharedManager].sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            success ? success(responseObject) : nil;
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[HY_NetworkManager sharedManager].sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            failure ? failure(error) : nil;
        });
    }];
    sessionTask ? [[HY_NetworkManager sharedManager].sessionTaskArray addObject:sessionTask] : nil;
    return sessionTask;
}

/**
 POST请求

 @param path        请求路径或者请求完整URL字符串
 @param parameters  请求参数
 @param success     请求成功的回调
 @param failure     请求失败的回调
 @return 返回的对象可取消请求，调用cancelRequestWithTask:方法
 */
+ (NSURLSessionTask *)POST:(nullable NSString *)path
                    parameters:(nullable id)parameters
                       success:(nullable HY_RequestSuccessBlock)success
                       failure:(nullable HY_RequestFailedBlock)failure {
    if ([HY_NetworkManager sharedManager].globalConfigBlock) {
        [HY_NetworkManager sharedManager].globalConfigBlock([HY_NetworkManager sharedManager].sessionManager);
    }
    if (path) {
        path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    }
    parameters = [self disposePublicParameters:parameters];
    NSURLSessionTask *sessionTask = [[HY_NetworkManager sharedManager].sessionManager POST:path parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[HY_NetworkManager sharedManager].sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            success ? success(responseObject) : nil;
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[HY_NetworkManager sharedManager].sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            failure ? failure(error) : nil;
        });
    }];
    sessionTask ? [[HY_NetworkManager sharedManager].sessionTaskArray addObject:sessionTask] : nil;
    return sessionTask;
}

/**
 上传文件
 @param fileData    文件二进制数据
 @param key         服务器是通过什么字段获取二进制就传什么，默认一般是：file
 @param fileName    保存在服务器时的文件名称
 @param mimeType    文件类型
 @param path        请求路径或者请求完整URL字符串
 @param parameters  请求参数
 @param success     请求成功的回调
 @param failure     请求失败的回调
 @return 返回的对象可取消请求，调用cancelRequestWithTask:方法
 */
+ (NSURLSessionTask *)uploadFile:(NSData *)fileData
                                 key:(nullable NSString *)key
                            fileName:(nullable NSString *)fileName
                            mimeType:(nullable NSString *)mimeType
                                path:(nullable NSString *)path
                          parameters:(nullable id)parameters
                        progress:(HY_NetWorkProgress _Nullable)progress
                         success:(nullable HY_RequestSuccessBlock)success
                         failure:(nullable HY_RequestFailedBlock)failure {
    if (!fileData || ![fileData isKindOfClass:[NSData class]] || fileData.length == 0) {
        return nil;
    }
    if ([HY_NetworkManager sharedManager].globalConfigBlock) {
        [HY_NetworkManager sharedManager].globalConfigBlock([HY_NetworkManager sharedManager].sessionManager);
    }
    if (path) {
        path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    }
    parameters = [self disposePublicParameters:parameters];
    NSURLSessionTask *sessionTask = [[HY_NetworkManager sharedManager].sessionManager POST:path parameters:parameters headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:fileData name:key fileName:fileName mimeType:mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress, uploadProgress.fractionCompleted) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[HY_NetworkManager sharedManager].sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            success ? success(responseObject) : nil;
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[HY_NetworkManager sharedManager].sessionTaskArray removeObject:task];
        dispatch_async(dispatch_get_main_queue(), ^{
            failure ? failure(error) : nil;
        });
    }];
    sessionTask ? [[HY_NetworkManager sharedManager].sessionTaskArray addObject:sessionTask] : nil;
    return sessionTask;
}

/**
 文件资源下载
 
 @param URLString 下载资源的URL
 @param folderName 下载资源的自定义保存目录文件夹名  传nil则保存至默认目录
 @param progress 下载进度
 @param comp 下载结果 error存在即代表下载停止或失败
 */
+ (NSURLSessionDownloadTask *_Nullable)downloadWithURL:(NSString *_Nullable)URLString folderName:(NSString *_Nullable)folderName progress:(HY_NetWorkProgress _Nullable )progress completion:(HY_NetWorkDownloadComp _Nullable )comp{
    if (!URLString) {
        URLString = @"";
    }
    
    NSString *downloadDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:folderName ? folderName : @"Download"];//拼接缓存目录
    NSString *fileName = URLString.lastPathComponent;
    NSString *downloadPath = [downloadDirectory stringByAppendingPathComponent:fileName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];//打开文件管理器
    BOOL fileExist = [fileManager fileExistsAtPath:downloadPath];
    if (fileExist) {
        comp ? comp(nil, [NSString stringWithFormat:@"%@",downloadPath], nil) : nil;
        return nil;
    }
    BOOL folderExist = [fileManager fileExistsAtPath:downloadDirectory];
    if (!folderExist) {
        [fileManager createDirectoryAtPath:downloadDirectory withIntermediateDirectories:YES attributes:nil error:nil];//创建Download目录
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    
    __block NSURLSessionDownloadTask *downloadTask = [[HY_NetworkManager sharedManager].sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress, downloadProgress.fractionCompleted) : nil;
        });
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:downloadPath];//返回文件位置的URL路径
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        comp ? comp(response, filePath.absoluteString, error) : nil;
        
    }];
    [downloadTask resume];
    
    return downloadTask;
}

/**
 文件资源接续下载  根据保存的data数据继续下载
 
 @param resumeData 用于继续下载的data数据
 @param folderName 下载资源的自定义保存目录文件夹名  传nil则保存至默认目录
 @param progress 下载进度
 @param comp 下载结果 error存在即代表下载停止或失败
 */
+ (NSURLSessionDownloadTask *_Nullable)downloadWithResumeData:(NSData *_Nonnull)resumeData folderName:(NSString *_Nullable)folderName progress:(HY_NetWorkProgress _Nullable )progress completion:(HY_NetWorkDownloadComp _Nullable )comp{
    __block NSURLSessionDownloadTask *downloadTask = [[HY_NetworkManager sharedManager].sessionManager downloadTaskWithResumeData:resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress, downloadProgress.fractionCompleted) : nil;
        });
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSString *downloadDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:folderName ? folderName : @"Download"];
        NSFileManager *fileManager = [NSFileManager defaultManager];//打开文件管理器
        BOOL folderExist = [fileManager fileExistsAtPath:downloadDirectory];
        if (!folderExist) {
            [fileManager createDirectoryAtPath:downloadDirectory withIntermediateDirectories:YES attributes:nil error:nil];//创建Download目录
        }
        NSString *filePath = [downloadDirectory stringByAppendingPathComponent:response.suggestedFilename];//拼接文件路径
        return [NSURL fileURLWithPath:filePath];//返回文件位置的URL路径
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        comp ? comp(response, filePath.absoluteString, error) : nil;
    }];
    [downloadTask resume];
    
    return downloadTask;
}

/**
 文件资源断点下载
 @param URLString 下载资源的URL
 @param resumeData 用于断点继续下载的data数据
 @param folderName 下载资源的自定义保存目录文件夹名  传nil则保存至默认目录
 @param progress 下载进度
 @param comp 下载结果 error存在即代表下载停止或失败
 */
+ (NSURLSessionDownloadTask *_Nullable)downloadResumeWithURL:(NSString *_Nullable)URLString ResumeData:(NSData *_Nullable)resumeData folderName:(NSString *_Nullable)folderName progress:(HY_NetWorkProgress _Nullable )progress completion:(HY_NetWorkDownloadComp _Nullable )comp{
    if (!URLString) {
        URLString = @"";
    }
    NSURLSessionDownloadTask *downloadTask = nil;
    if (resumeData.length > 0) {//存在已下载任务 继续下载
        downloadTask = [self downloadWithResumeData:resumeData folderName:folderName progress:progress completion:comp];
    }else {//新任务下载
        downloadTask= [self downloadWithURL:URLString folderName:folderName progress:progress completion:comp];
    }
    
    return downloadTask;
}

/** 取消指定的HTTP请求 */
+ (void)cancelRequestWithTask:(NSURLSessionTask *)task {
    if (![task isKindOfClass:[NSURLSessionTask class]]) return;
    @synchronized (self) {
        for (id obj in [HY_NetworkManager sharedManager].sessionTaskArray) {
            if ([obj isEqual:task]) {
                [task cancel];
                [[HY_NetworkManager sharedManager].sessionTaskArray removeObject:obj];
                break;
            }
        }
    }
}

/** 取消所有HTTP请求 */
+ (void)cancelAllRequest {
    @synchronized (self) {
        for (id obj in [HY_NetworkManager sharedManager].sessionTaskArray) {
            [((NSURLSessionTask *)obj) cancel];
        }
        [[HY_NetworkManager sharedManager].sessionTaskArray removeAllObjects];
    }
}

/** 设置HTTPHeader */
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [[HY_NetworkManager sharedManager].sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

/**
 配置自建证书的HTTPS请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103

 @param cerPath 自建HTTPS证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO;

 即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName = NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外一个域名。
 因为SSL证书上的域名是独立的,假如证书上注册的域名是www.example.com, 那么mail.example.com是无法验证通过的.
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName {
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 如果需要验证自建证书(无效证书)，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES;
    securityPolicy.validatesDomainName = validatesDomainName;
    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    [[HY_NetworkManager sharedManager].sessionManager setSecurityPolicy:securityPolicy];
}

#pragma mark - 参数处理 添加公共参数♻️
+ (NSDictionary *)disposePublicParameters:(NSDictionary *)parameters {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
    if ([HY_NetworkManager sharedManager].publicParams && [HY_NetworkManager sharedManager].publicParams.count > 0) {
        [params addEntriesFromDictionary:[HY_NetworkManager sharedManager].publicParams];//添加公共参数
    }
    return params.copy;
}

@end
