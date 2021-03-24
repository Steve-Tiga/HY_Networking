# HY_Networking

[![CI Status](https://img.shields.io/travis/Baffin-HSL/HY_Networking.svg?style=flat)](https://travis-ci.org/Baffin-HSL/HY_Networking)
[![Version](https://img.shields.io/cocoapods/v/HY_Networking.svg?style=flat)](https://cocoapods.org/pods/HY_Networking)
[![License](https://img.shields.io/cocoapods/l/HY_Networking.svg?style=flat)](https://cocoapods.org/pods/HY_Networking)
[![Platform](https://img.shields.io/cocoapods/p/HY_Networking.svg?style=flat)](https://cocoapods.org/pods/HY_Networking)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

HY_Networking is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'HY_Networking'
```

## 方法使用
###  1.post请求

```
NSDictionary *parameters = @{@"name": @"古风二首 二"};
[HY_NetworkManager POST:@"https://api.apiopen.top/searchPoetry" parameters:parameters success:^(id  _Nonnull responseObject) {
    NSLog(@"responseObject:%@",responseObject);
} failure:^(NSError * _Nonnull error) {
    
}];
```

### 2. get请求
```
//该请求需要设置参数key，我这里把key当做公共参数，如需测试请吧appdelegate中设置公共参数的代码取消注释
NSDictionary *parameters = @{@"city":@"北京"};
[HY_NetworkManager GET:@"http://apis.juhe.cn/simpleWeather/query" parameters:parameters success:^(id  _Nonnull responseObject) {
    NSLog(@"responseObject:%@",responseObject);
} failure:^(NSError * _Nonnull error) {
    
}];

```

### 3. 断点下载
```
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


```

### 4.上传文件

```
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
```



## Author

Baffin-HSL, 15574662657@163.com

## License

HY_Networking is available under the MIT license. See the LICENSE file for more info.
