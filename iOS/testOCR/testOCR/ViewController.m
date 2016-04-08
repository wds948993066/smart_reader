//
//  ViewController.m
//  testOCR
//
//  Created by lei.qiao on 16/3/8.
//  Copyright © 2016年 LeiQiao. All rights reserved.
//

#import "ViewController.h"
#import "CPCameraView.h"
#import "IDCardLayer.h"
#import "HUD.h"
#import "UIImage-Extensions.h"
#import "RecognizeViewController.h"
#import "UIImage+Denoise.h"
#import "SelectIDViewController.h"
#import <sys/utsname.h>

@interface ViewController ()

@end

@implementation ViewController {
    UINavigationItem* _barItem;
    CPCameraView* _cameraView;
    BOOL _takingPicture;
    
    CALayer* _cutLayer;
    
    UIImageView* _idCardMask;
    
    UIImageView* _imageView;
    
    NSDictionary* _idData;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _cameraView = [[CPCameraView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-0)];
    _cameraView.delegate = (id<CPCameraViewDelegate>)self;
    [self.view addSubview:_cameraView];
    
    CGRect rect = CGRectMake(40, 0, self.view.frame.size.width-80, 0);
    rect.size.height = rect.size.width * 320 / 205;
    rect.origin.y = (self.view.frame.size.height-rect.size.height)/2;
    
    _cutLayer = [IDCardLayer layer];
    _cutLayer.frame = rect;
    
    [_cameraView.layer addSublayer:_cutLayer];
    [_cutLayer setNeedsDisplay];
    
    _idCardMask = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"idcard_mask.png"]];
    _idCardMask.frame = rect;
    [_cameraView addSubview:_idCardMask];
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height-64)];
    [self.view addSubview:_imageView];
    
//    [NSThread detachNewThreadSelector:@selector(takePictureThread)
//                             toTarget:self
    
//                           withObject:nil];
    
    UINavigationBar* bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    _barItem = [[UINavigationItem alloc] initWithTitle:@""];
    _barItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"选择号码"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(onSelectSample:)];
    _barItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"拍照上传"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(onTakeShot:)];
    [bar pushNavigationItem:_barItem animated:NO];
    [self.view addSubview:bar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDidSelectSample:)
                                                 name:kSelectIDNotification
                                               object:nil];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if( !_idData )
    {
        SelectIDViewController* vc = [[SelectIDViewController alloc] init];
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) takePictureThread
{
    while( YES )
    {
        if( _takingPicture ) continue;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _takingPicture = YES;
            [_cameraView takePicture];
        });
    }
}

-(UIImage*) cutIDCardImage:(UIImage*)image
{
    CGFloat xs = image.size.width / _cameraView.frame.size.width;
    CGFloat ys = image.size.height / _cameraView.frame.size.height;
    
    CGRect cutFrame = _cutLayer.frame;
    cutFrame.origin.x *= xs;
    cutFrame.origin.y *= ys;
    cutFrame.size.width *= xs;
    cutFrame.size.height *= ys;
    
    CGFloat swap = cutFrame.origin.x;
    cutFrame.origin.x = cutFrame.origin.y;
    cutFrame.origin.y = swap;
    
    swap = cutFrame.size.width;
    cutFrame.size.width = cutFrame.size.height;
    cutFrame.size.height = swap;
    
    return [image imageAtRect:cutFrame];
}

-(UIImage*) cutIDNumberFromIDCardImage:(UIImage*)image
{
    CGRect cutFrame = CGRectZero;
    cutFrame.origin.y = image.size.height / 11 * 8;
    cutFrame.size.width = image.size.width;
    cutFrame.size.height = image.size.height - cutFrame.origin.y;
    
    return [image imageAtRect:cutFrame];
}

-(void) savePictureToDocument:(UIImage*)image
{
    NSString* outputPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString* filePath = [NSString stringWithFormat:@"%@/%ld.jpg", outputPath, (long)[NSDate date].timeIntervalSince1970];
    NSLog(@"%@", filePath);
    
    [UIImageJPEGRepresentation(image, 90) writeToFile:filePath atomically:YES];
}

-(void) savePictureToRemote:(UIImage*)image
{
    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.3.88:8080/"]];
    [request setHTTPMethod:@"POST"];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request setValue:@"http://192.168.3.88:8080/" forHTTPHeaderField: @"referer"];
    
    NSMutableData *httpBody = [NSMutableData data];
    
    {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYYMMddHHmmss"];
        NSString* filename = [NSString stringWithFormat:@"%@_%@_%@_%@.jpg", [_idData objectForKey:@"id"], [_idData objectForKey:@"name"], [[self class] deviceVersion], [formatter stringFromDate:[NSDate date]]];
        
        NSData* imageData = UIImageJPEGRepresentation(image, 0.8);
        
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type:  image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:imageData];
        [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [request setHTTPBody:httpBody];
    [request setValue:[NSString stringWithFormat:@"%u", (unsigned)[httpBody length]]
   forHTTPHeaderField:@"Content-Length"];
    [NSURLConnection connectionWithRequest:request delegate:self];
    
    popWaitingWithHint(@"正在上传...");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    dismissWaiting();
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"上传失败"
                                                 message:@"1.请用内网上传 2.请联网 3.网络稳定 4.刷新人品 5.参考4"
                                                delegate:nil
                                       cancelButtonTitle:@"确定"
                                       otherButtonTitles:nil];
    [av show];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    dismissWaiting();
    popSuccess(@"发送成功");
}

-(void) didTakePicture:(UIImage*)picture
{
    picture = [self cutIDCardImage:picture];
//    picture = [picture imageRotatedByDegrees:180];
    _imageView.image = [picture imageRotatedByDegrees:90];
    NSLog(@"id card size:(%.02f : %.02f)", picture.size.width, picture.size.height);
    
//    RecognizeViewController* recognizeVC = [[RecognizeViewController alloc] initWithIDCard:picture];
//    [self presentViewController:recognizeVC animated:YES completion:nil];
    
//    [self savePictureToDocument:picture];
//    UIImageWriteToSavedPhotosAlbum(picture, nil, nil, nil);
    [self savePictureToRemote:picture];
}

-(void) onSelectSample:(id)sender
{
    SelectIDViewController* vc = [[SelectIDViewController alloc] init];
    [self presentViewController:vc animated:YES completion:^{}];
}

-(void) onDidSelectSample:(NSNotification*)notify
{
    _idData = notify.object;
    
    _barItem.title = [NSString stringWithFormat:@"%@ (%@)", [_idData objectForKey:@"name"], [_idData objectForKey:@"id"]];
}

-(void) onTakeShot:(id)sender
{
    if( _imageView.image )
    {
        _imageView.image = nil;
        return;
    }
    else
    {
        [_cameraView takePicture];
    }
}

+ (NSString*)deviceVersion
{
    // 需要#import "sys/utsname.h"
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    //iPhone
    if ([deviceString isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([deviceString isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([deviceString isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([deviceString isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone3,2"])    return @"Verizon iPhone 4";
    if ([deviceString isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([deviceString isEqualToString:@"iPhone5,1"])    return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,3"])    return @"iPhone 5C";
    if ([deviceString isEqualToString:@"iPhone5,4"])    return @"iPhone 5C";
    if ([deviceString isEqualToString:@"iPhone6,1"])    return @"iPhone 5S";
    if ([deviceString isEqualToString:@"iPhone6,2"])    return @"iPhone 5S";
    if ([deviceString isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([deviceString isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([deviceString isEqualToString:@"iPhone8,1"])    return @"iPhone 6s";
    if ([deviceString isEqualToString:@"iPhone8,2"])    return @"iPhone 6s Plus";
    
    //iPod
    if ([deviceString isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([deviceString isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([deviceString isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([deviceString isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([deviceString isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    
    //iPad
    if ([deviceString isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([deviceString isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([deviceString isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([deviceString isEqualToString:@"iPad2,4"])      return @"iPad 2 (32nm)";
    if ([deviceString isEqualToString:@"iPad2,5"])      return @"iPad mini (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,6"])      return @"iPad mini (GSM)";
    if ([deviceString isEqualToString:@"iPad2,7"])      return @"iPad mini (CDMA)";
    
    if ([deviceString isEqualToString:@"iPad3,1"])      return @"iPad 3(WiFi)";
    if ([deviceString isEqualToString:@"iPad3,2"])      return @"iPad 3(CDMA)";
    if ([deviceString isEqualToString:@"iPad3,3"])      return @"iPad 3(4G)";
    if ([deviceString isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([deviceString isEqualToString:@"iPad3,5"])      return @"iPad 4 (4G)";
    if ([deviceString isEqualToString:@"iPad3,6"])      return @"iPad 4 (CDMA)";
    
    if ([deviceString isEqualToString:@"iPad4,1"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad4,2"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad4,3"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad5,3"])      return @"iPad Air 2";
    if ([deviceString isEqualToString:@"iPad5,4"])      return @"iPad Air 2";
    if ([deviceString isEqualToString:@"i386"])         return @"Simulator";
    if ([deviceString isEqualToString:@"x86_64"])       return @"Simulator";
    
    if ([deviceString isEqualToString:@"iPad4,4"]
        ||[deviceString isEqualToString:@"iPad4,5"]
        ||[deviceString isEqualToString:@"iPad4,6"])      return @"iPad mini 2";
    
    if ([deviceString isEqualToString:@"iPad4,7"]
        ||[deviceString isEqualToString:@"iPad4,8"]
        ||[deviceString isEqualToString:@"iPad4,9"])      return @"iPad mini 3";
    
    return deviceString;
}

@end
