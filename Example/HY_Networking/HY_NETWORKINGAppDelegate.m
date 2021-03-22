//
//  HY_NETWORKINGAppDelegate.m
//  HY_Networking
//
//  Created by Baffin-HSL on 03/17/2021.
//  Copyright (c) 2021 Baffin-HSL. All rights reserved.
//

#import "HY_NETWORKINGAppDelegate.h"
#import "HY_NetworkManager.h"

@implementation HY_NETWORKINGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // 设置全局网络请求
    [HY_NetworkManager globalConfigWithBlock:^(AFHTTPSessionManager * _Nonnull sessionManager) {
        // 可以在这里设置请求超时时间，默认是30秒
        sessionManager.requestSerializer.timeoutInterval = 60.0f;
        // 可以在这里设置请求头，也可以调用setValue:forHTTPHeaderField:进行单独设置
//        [sessionManager.requestSerializer setValue:@"cookie" forHTTPHeaderField:@"Cookie"];
    }];

    // 监听网络状态
    [HY_NetworkManager startMonitoringNetworkStatusWithBlock:^(HY_NetworkStatus status) {
        // 在这里进行一些提醒，在Debug模式下，会在控制台自动log网络状态
    }];
    
//    NSMutableDictionary *keyDic = [NSMutableDictionary dictionary];
//    [keyDic setValue:@"2dca7299f47cae1ada2ab1b864f3ce8c" forKey:@"key"];
//    [HY_NetworkManager setPublicParams:keyDic];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
