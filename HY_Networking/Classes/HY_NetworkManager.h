//
//  HY_NetworkManager.h
//  HY_Networking_Example
//
//  Created by 猫态科技 on 2021/3/19.
//  Copyright © 2021 Baffin-HSL. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AFNetworking;
NS_ASSUME_NONNULL_BEGIN

/** 网络状态 */
typedef NS_ENUM(NSInteger, HY_NetworkStatus) {
    /** 未知网络 */
    HY_NetworkStatusUnknown,
    /** 无网络 */
    HY_NetworkStatusNotReachable,
    /** 运营商网络 */
    HY_NetworkStatusReachableViaWWAN,
    /** WIFI网络 */
    HY_NetworkStatusReachableViaWiFi
};
/**
 请求成功的block
 @param responseObject 返回数据
 */
typedef void(^HY_RequestSuccessBlock)(id responseObject);

/**
 请求失败的block
 @param error 错误信息
 */
typedef void(^HY_RequestFailedBlock)(NSError *error);

/**
 网络状态的block
 @param status 网络状态
 */
typedef void(^HY_NetworkStatusBlock)(HY_NetworkStatus status);

/** 数据下载或上传进度及比例 */
typedef void(^HY_NetWorkProgress)(NSProgress * _Nonnull progress, double progressRate);

/** 文件资源下载结果回调 */
typedef void(^HY_NetWorkDownloadComp)(NSURLResponse * _Nullable response, NSString * _Nullable filePath, NSError * _Nullable error);

@interface HY_NetworkManager : NSObject

#pragma mark - ******* 基本设置 ********
/**
 在这里进行网络请求的全局配置，每次发送请求都会调用该block
 */
+ (void)globalConfigWithBlock:(nullable void(^)(AFHTTPSessionManager *sessionManager))completion;
/** 设置HTTPHeader */
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/** 设置公共参数 */
+ (void)setPublicParams:(NSMutableDictionary *)publicParams;

#pragma mark - ******* 网络监听 ********
/** 开始监听网络状态，一旦状态发生变化，将会通过block返回 */
+ (void)startMonitoringNetworkStatusWithBlock:(nullable HY_NetworkStatusBlock)block;

/** 当前网络状态，默认为HY_NetworkStatusUnknown，调用方法后可获取真实值：startMonitoringNetworkStatusWithBlock: */
+ (HY_NetworkStatus)getNetworkStatus;


#pragma mark - ******* 普通请求 ********
/**
 GET请求

 @param path        请求路径或者请求完整URL字符串（如果是路径，则需要设置baseURL）
 @param parameters  请求参数
 @param success     请求成功的回调
 @param failure     请求失败的回调
 @return 返回的对象可取消请求，调用cancelRequestWithTask:方法
 */
+ (NSURLSessionTask *)GET:(nullable NSString *)path
                   parameters:(nullable id)parameters
                      success:(nullable HY_RequestSuccessBlock)success
                      failure:(nullable HY_RequestFailedBlock)failure;

/**
 POST请求

 @param path        请求路径或者请求完整URL字符串（如果是路径，则需要设置baseURL）
 @param parameters  请求参数
 @param success     请求成功的回调
 @param failure     请求失败的回调
 @return 返回的对象可取消请求，调用cancelRequestWithTask:方法
 */
+ (NSURLSessionTask *)POST:(nullable NSString *)path
                    parameters:(nullable id)parameters
                       success:(nullable HY_RequestSuccessBlock)success
                       failure:(nullable HY_RequestFailedBlock)failure;


#pragma mark - ******* 上传下载 ********
/**
 上传文件

 @param fileData    文件二进制数据
 @param key         服务器是通过什么字段获取二进制就传什么，默认一般是：file
 @param fileName    保存在服务器时的文件名称
 @param mimeType    文件类型
 @param path        请求路径或者请求完整URL字符串（如果是路径，则需要设置baseURL）
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
                          parameters:(nullable id)parameters progress:(HY_NetWorkProgress _Nullable )progress
                             success:(nullable HY_RequestSuccessBlock)success
                             failure:(nullable HY_RequestFailedBlock)failure;

/**
 文件资源下载
 
 @param URLString 下载资源的URL
 @param folderName 下载资源的自定义保存目录文件夹名  传nil则保存至默认目录
 @param progress 下载进度
 @param comp 下载结果 error存在即代表下载停止或失败
 */
+ (NSURLSessionDownloadTask *_Nullable)downloadWithURL:(NSString *_Nullable)URLString folderName:(NSString *_Nullable)folderName progress:(HY_NetWorkProgress _Nullable )progress completion:(HY_NetWorkDownloadComp _Nullable )comp;

/**
 文件资源断点下载
 
 @param URLString 下载资源的URL
 @param resumeData 用于断点继续下载的data数据
 @param folderName 下载资源的自定义保存目录文件夹名  传nil则保存至默认目录
 @param progress 下载进度
 @param comp 下载结果 error存在即代表下载停止或失败
 */
+ (NSURLSessionDownloadTask *_Nullable)downloadResumeWithURL:(NSString *_Nullable)URLString ResumeData:(NSData *_Nullable)resumeData folderName:(NSString *_Nullable)folderName progress:(HY_NetWorkProgress _Nullable )progress completion:(HY_NetWorkDownloadComp _Nullable )comp;


#pragma mark - ******* 取消请求 ********
/** 取消指定的HTTP请求 */
+ (void)cancelRequestWithTask:(NSURLSessionTask *)task;

/** 取消所有HTTP请求 */
+ (void)cancelAllRequest;

/**
 配置自建证书的HTTPS请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103

 @param cerPath 自建HTTPS证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO;

 即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName = NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外一个域名。
 因为SSL证书上的域名是独立的,假如证书上注册的域名是www.example.com, 那么mail.example.com是无法验证通过的.
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName;


@end

NS_ASSUME_NONNULL_END
