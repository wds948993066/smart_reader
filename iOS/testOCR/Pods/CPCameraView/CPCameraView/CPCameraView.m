//
//  CPCameraView.m
//  CPCameraView
//

#import "CPCameraView.h"

@implementation CPCameraView {
    AVCaptureSession* _session;
    AVCaptureDevice* _inputDevice;
    AVCaptureDeviceInput* _input;
    AVCaptureOutput* _output;
    AVCaptureVideoPreviewLayer* _cameraLayer;
}


#pragma mark
#pragma mark helper

-(void) beginScan
{
    // 初始化链接对象
    _session = [[AVCaptureSession alloc] init];
    
    // 高质量采集率
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    
    // 添加输入输出流
    if( _input )
    {
        [_session addInput:_input];
    }
    if( _output )
    {
        [_session addOutput:_output];
    }
    
    // 创建实时图像layer
    _cameraLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _cameraLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    _cameraLayer.frame = self.layer.bounds;
    [self.layer insertSublayer:_cameraLayer atIndex:0];
    
    //开始捕获
    [_session startRunning];
}

#pragma mark
#pragma mark init & dealloc

-(instancetype) initWithFrame:(CGRect)newFrame
{
    if( self = [super initWithFrame:newFrame] )
    {
        [self beginScan];
        self.cameraPosition = AVCaptureDevicePositionBack;
        self.outputType = CPCameraViewOutputTypePicture;
    }
    return self;
}

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
    if( self = [super initWithCoder:aDecoder] )
    {
        [self beginScan];
        self.cameraPosition = AVCaptureDevicePositionBack;
        self.outputType = CPCameraViewOutputTypePicture;
    }
    
    return self;
}

-(void) dealloc
{
    [_session stopRunning];
}

#pragma mark
#pragma mark override

-(void) layoutSubviews
{
    _cameraLayer.frame = self.layer.bounds;
    [super layoutSubviews];
}

-(void) setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    
    if( hidden )
    {
        [_session stopRunning];
    }
    else
    {
        [_session startRunning];
    }
}

-(void) setCameraPosition:(AVCaptureDevicePosition)newPosition
{
    if( _cameraPosition == newPosition ) return;
    
    _cameraPosition = newPosition;
    [_session removeInput:_input];
    
    // 选择输入设备
    _inputDevice = nil;
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for( AVCaptureDevice* device in devices )
    {
        if( device.position == _cameraPosition )
        {
            _inputDevice = device;
            break;
        }
    }
    
    // 默认输入设备
    if( _inputDevice == nil )
    {
        _inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    // 创建输入流
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_inputDevice error:nil];
    
    if( _input )
    {
        [_session addInput:_input];
    }
}

-(void) setOutputType:(CPCameraViewOutputType)newType
{
    if( _outputType == newType ) return;
    
    _outputType = newType;
    [_session removeOutput:_output];
    
    // 创建输出流
    if( _outputType == CPCameraViewOutputTypeBarCode )
    {
        AVCaptureMetadataOutput* output = [[AVCaptureMetadataOutput alloc] init];
        
        // 设置代理 在主线程里刷新
        [output setMetadataObjectsDelegate:(id<AVCaptureMetadataOutputObjectsDelegate>)self
                                     queue:dispatch_get_main_queue()];
        // 设置有效扫描区域
//        CGRect scanCrop = [self getScanCrop:_scanWindow.bounds readerViewBounds:self.bounds];
//        output.rectOfInterest = scanCrop;
        
        _output = output;
    }
    else if( _outputType == CPCameraViewOutputTypePicture )
    {
        AVCaptureStillImageOutput* output = [[AVCaptureStillImageOutput alloc] init];
        
        // 输出图像的编码方式
        output.outputSettings = @{(id)AVVideoCodecKey : AVVideoCodecJPEG};
        
        _output = output;
    }
    
    if( _output )
    {
        [_session addOutput:_output];
    }
    
    // 设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    if( _outputType == CPCameraViewOutputTypeBarCode )
    {
        ((AVCaptureMetadataOutput*)_output).metadataObjectTypes = @[AVMetadataObjectTypeQRCode,
                                       AVMetadataObjectTypeEAN13Code,
                                       AVMetadataObjectTypeEAN8Code,
                                       AVMetadataObjectTypeCode128Code];
    }
}

#pragma mark
#pragma mark member functions

/*!
 *  @author LeiQiao, 16-03-08
 *  @brief 拍照，拍照完毕调用delegate的didTakePicture方法
 */
-(void) takePicture
{
    // 如果不是拍照流，则调用失败
    if( self.outputType != CPCameraViewOutputTypePicture )
    {
        if( _delegate )
        {
            [_delegate performSelector:@selector(didTakePicture:) withObject:nil];
        }
        return;
    }
    
    // 选择connection
    AVCaptureConnection* videoConnection = nil;
    for( AVCaptureConnection *connection in _output.connections )
    {
        for( AVCaptureInputPort* port in [connection inputPorts] )
        {
            if( [[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    if( !videoConnection )
    {
        if( _delegate )
        {
            [_delegate performSelector:@selector(didTakePicture:) withObject:nil];
        }
        return;
    }
    
    // 获取connection中的图片流
    [(AVCaptureStillImageOutput*)_output captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if( imageDataSampleBuffer )
        {
            NSData* imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage* image = [[UIImage alloc] initWithData:imageData];
            
            // 成功获取图像
            if( _delegate )
            {
                [_delegate performSelector:@selector(didTakePicture:) withObject:image];
            }
        }
        else
        {
            // 获取图像失败
            if( _delegate )
            {
                [_delegate performSelector:@selector(didTakePicture:) withObject:nil];
            }
        }
    }];
}

#pragma mark
#pragma mark AVCaptureMetadataOutputObjectsDelegate

-(void) captureOutput:(AVCaptureOutput*)captureOutput
didOutputMetadataObjects:(NSArray*)metadataObjects
       fromConnection:(AVCaptureConnection*)connection
{
    if( metadataObjects.count == 0 ) return;
    
    AVMetadataMachineReadableCodeObject* object = [metadataObjects objectAtIndex:0];
    NSString* barCodeValue = object.stringValue;
    
    if( _delegate )
    {
        [_delegate performSelector:@selector(didRecogniedBarCode:) withObject:barCodeValue];
    }
}

@end
