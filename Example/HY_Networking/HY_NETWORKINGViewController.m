//
//  HY_NETWORKINGViewController.m
//  HY_Networking
//
//  Created by Baffin-HSL on 03/17/2021.
//  Copyright (c) 2021 Baffin-HSL. All rights reserved.
//

#import "HY_NETWORKINGViewController.h"
#import "HY_NetworkManager.h"
#import <AVFoundation/AVFoundation.h>

#define DOWNLOAD_VIDEO_URL @"https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4"

@interface HY_NETWORKINGViewController ()

@property (weak, nonatomic) IBOutlet UIProgressView *resumeDownloadProgress;
@property (weak, nonatomic) IBOutlet UILabel *resumeDownloadLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (nonatomic,copy) NSString *resumeDownloadPath;//下载路径
/** *********断点下载相关********* */
/**  下载历史记录 */
@property (nonatomic,strong) NSMutableDictionary *downLoadHistoryDictionary;
@property (nonatomic,strong) NSString *fileHistoryPath;

@end

@implementation HY_NETWORKINGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
}
- (IBAction)postRequestAction:(id)sender {
    [self postRequest];
}
- (IBAction)getRequestAction:(id)sender {
    [self getRequest];
}

- (IBAction)downloadAction:(UIButton *)sender {
    [self resumeDownloadSetting];
    
    static NSURLSessionDownloadTask *resumeTask=nil;
    
    if (!sender.selected) {
        NSData *downLoadHistoryData = [self.downLoadHistoryDictionary objectForKey:DOWNLOAD_VIDEO_URL];
        resumeTask=[HY_NetworkManager downloadResumeWithURL:DOWNLOAD_VIDEO_URL ResumeData:downLoadHistoryData folderName:nil progress:^(NSProgress * _Nonnull progress, double progressRate) {
            self.resumeDownloadProgress.progress=progressRate;
            self.resumeDownloadLabel.text=[NSString stringWithFormat:@"%.f%%",progressRate*100];
        } completion:^(NSURLResponse * _Nullable response, NSString * _Nullable filePath, NSError * _Nullable error) {
            
            if (error) {
                if (error.code == -1001) {
                    NSLog(@"下载出错,看一下网络是否正常");
                }
                NSData *resumeData = [error.userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"];
                [self saveDownloadHistoryWithKey:DOWNLOAD_VIDEO_URL downloadTaskResumeData:resumeData];
            }else{
                NSLog(@"%@",self.downLoadHistoryDictionary);
                if ([self.downLoadHistoryDictionary valueForKey:DOWNLOAD_VIDEO_URL]) {
                    //下载完应删除infoplist中的数据，以防下次接着断点下载
                    [self.downLoadHistoryDictionary removeObjectForKey:DOWNLOAD_VIDEO_URL];
                    NSLog(@"%@",self.downLoadHistoryDictionary);
                }
                NSLog(@"%@*****下载文件路径*",filePath);
                self.resumeDownloadPath=filePath;
            }
        }];
        
    }else{
        [resumeTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            //停止下载
        }];
    }
    sender.selected = !sender.selected;
}

- (IBAction)removeResumeDownloadFile:(id)sender {
//    [[NSFileManager defaultManager] removeItemAtURL:[NSURL URLWithString:self.resumeDownloadPath] error:nil];
    [self resumeDownloadSetting];
    NSURL *sourceMovieURL = [NSURL URLWithString:self.resumeDownloadPath];
    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = CGRectMake(0, 20, 300, 300);

    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];

    [player play];

    UIView *videoMaskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 250)];
    videoMaskView.backgroundColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.3];
    [self.view addSubview:videoMaskView];
}

- (IBAction)uploadFileAction:(id)sender {
    
}

#pragma mark - ******* post请求 ********
-(void)postRequest{
    NSDictionary *parameters = @{@"name": @"古风二首 二"};
    [HY_NetworkManager POST:@"https://api.apiopen.top/searchPoetry" parameters:parameters success:^(id  _Nonnull responseObject) {
        NSLog(@"responseObject:%@",responseObject);
    } failure:^(NSError * _Nonnull error) {
        
    }];
}

#pragma mark - ******* get请求 ********
-(void)getRequest{
    //该请求需要设置参数key，我这里把key当做公共参数，类似token之类的，如需测试请吧appdelegate中设置公共参数的代码取消注释
    NSDictionary *parameters = @{@"city":@"北京"};
    [HY_NetworkManager GET:@"http://apis.juhe.cn/simpleWeather/query" parameters:parameters success:^(id  _Nonnull responseObject) {
        NSLog(@"responseObject:%@",responseObject);
    } failure:^(NSError * _Nonnull error) {
        
    }];
}

#pragma mark - ******* 上传文件 ********
-(void)uploadFile{
    
}

#pragma mark - ******* 断点下载 ********
- (void)resumeDownloadSetting {
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path=[paths objectAtIndex:0];
    self.fileHistoryPath=[path stringByAppendingPathComponent:@"fileDownLoadHistory.plist"];
    NSLog(@"%@",self.fileHistoryPath);
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.fileHistoryPath]) {
        self.downLoadHistoryDictionary =[NSMutableDictionary dictionaryWithContentsOfFile:self.fileHistoryPath];
    }else{
        self.downLoadHistoryDictionary =[NSMutableDictionary dictionary];
        //将dictionary中的数据写入plist文件中
        [self.downLoadHistoryDictionary writeToFile:self.fileHistoryPath atomically:YES];
    }
}


- (void)saveDownloadHistoryWithKey:(NSString *)key downloadTaskResumeData:(NSData *)data{
    if (!data) {
        NSString *emptyData = [NSString stringWithFormat:@""];
        [self.downLoadHistoryDictionary setObject:emptyData forKey:key];

    }else{
        [self.downLoadHistoryDictionary setObject:data forKey:key];
    }
    [self.downLoadHistoryDictionary writeToFile:self.fileHistoryPath atomically:NO];
}

@end
