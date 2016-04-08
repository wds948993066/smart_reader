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
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.3.88:9191/images/"]];
    [request setHTTPMethod:@"POST"];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request setValue:@"http://192.168.3.88:9191/images/" forHTTPHeaderField: @"referer"];
    
    NSMutableData *httpBody = [NSMutableData data];
    
    {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYYMMddHHmmss"];
        NSString* filename = [NSString stringWithFormat:@"%@_%@_%@.jpg", [_idData objectForKey:@"id"], [_idData objectForKey:@"name"], [formatter stringFromDate:[NSDate date]]];
        
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

@end
