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

@interface HY_NETWORKINGViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIProgressView *resumeDownloadProgress;
@property (weak, nonatomic) IBOutlet UILabel *resumeDownloadLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (nonatomic,copy) NSString *resumeDownloadPath;//下载路径
/** *********断点下载相关********* */
/**  下载历史记录 */
@property (nonatomic,strong) NSMutableDictionary *downLoadHistoryDictionary;//保存下载任务
@property (nonatomic,strong) NSString *fileHistoryPath;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
@property (weak, nonatomic) IBOutlet UIProgressView *uploadFileProgress;
@property (weak, nonatomic) IBOutlet UILabel *uploadFileLabel;
@property (nonatomic,strong) UIImage *uploadImage;


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
    static NSURLSessionDownloadTask *resumeTask=nil;
    if (!sender.selected) {
        //获取是否有正在下载的任务
        [self resumeDownloadSetting];
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
                //暂停或者网络出错或者关闭程序停止下载，将下载的任务保存，下次直接取出继续下载
                [self saveDownloadHistoryWithKey:DOWNLOAD_VIDEO_URL downloadTaskResumeData:resumeData];
            }else{
                [self resumeDownloadSetting];
                if ([self.downLoadHistoryDictionary valueForKey:DOWNLOAD_VIDEO_URL]) {
                    //下载完取消infoplist中的对应的下载任务
                    [self.downLoadHistoryDictionary removeObjectForKey:DOWNLOAD_VIDEO_URL];
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
    [self resumeDownloadSetting];
    if ([self.downLoadHistoryDictionary valueForKey:DOWNLOAD_VIDEO_URL]) {
        //取消infoplist中的对应的下载任务
        [self.downLoadHistoryDictionary removeObjectForKey:DOWNLOAD_VIDEO_URL];
    }
    [[NSFileManager defaultManager] removeItemAtURL:[NSURL URLWithString:self.resumeDownloadPath] error:nil];

}
- (IBAction)player:(UIButton *)sender {
    if (!sender.selected) {
        [self.view.layer addSublayer:self.playerLayer];
    }else{
        [self.playerLayer removeFromSuperlayer];
    }
    sender.selected = !sender.selected;
}

- (IBAction)uploadFileAction:(id)sender {
    UIImagePickerController *pic = [[UIImagePickerController alloc] init];
    pic.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    pic.delegate = self;
    [self presentViewController:pic animated:YES completion:nil];
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
    //该请求需要设置参数key，我这里把key当做公共参数，如需测试请吧appdelegate中设置公共参数的代码取消注释
    NSDictionary *parameters = @{@"city":@"北京"};
    [HY_NetworkManager GET:@"http://apis.juhe.cn/simpleWeather/query" parameters:parameters success:^(id  _Nonnull responseObject) {
        NSLog(@"responseObject:%@",responseObject);
    } failure:^(NSError * _Nonnull error) {
        
    }];
}

#pragma mark - ******* 上传文件 ********
-(void)uploadFile{
    NSData *data = UIImageJPEGRepresentation(self.uploadImage, 0.7f);
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyy-MM-dd-HH-mm-ss";
    NSString *str = [formatter stringFromDate:[NSDate date]];
    NSString *imageName = [NSString stringWithFormat:@"%@.jpg",str];
    [HY_NetworkManager uploadFile:data key:@"myfile[]" fileName:imageName mimeType:@"image/jpeg" path:@"抱歉，我用的公司接口测试的。如有需要还请另找接口！！！" parameters:nil progress:^(NSProgress * _Nonnull progress, double progressRate) {
        self.uploadFileProgress.progress=progressRate;
        self.uploadFileLabel.text=[NSString stringWithFormat:@"%.f%%",progressRate*100];
    } success:^(id  _Nonnull responseObject) {

    } failure:^(NSError * _Nonnull error) {
        
    }];
}

#pragma mark - ******* 断点下载 ********
//获取下载任务列表，[self.downLoadHistoryDictionary objectForKey:DOWNLOAD_VIDEO_URL]=nil则是新下载任务
- (void)resumeDownloadSetting {
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path=[paths objectAtIndex:0];
    self.fileHistoryPath=[path stringByAppendingPathComponent:@"fileDownLoadHistory.plist"];
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

-(AVPlayerLayer *)playerLayer{
    if (!_playerLayer) {
        [self resumeDownloadSetting];
        NSURL *sourceMovieURL = [NSURL URLWithString:self.resumeDownloadPath];
        AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        _playerLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, 200);
        _playerLayer.backgroundColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.3].CGColor;
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [player play];
    }
    return _playerLayer;
}

#pragma mark - ******* UIImagePickerControllerDelegate ********
//点击相片后会跑这个方法
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    //拿到图片会就销毁之前的控制器
    [picker dismissViewControllerAnimated:YES completion:nil];
    //info中就是包含你在相册里面选择的图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    self.uploadImage = image;
    [self uploadFile];
}

@end
