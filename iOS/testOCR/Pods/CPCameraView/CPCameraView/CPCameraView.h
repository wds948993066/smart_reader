//
//  CPCameraView.h
//  CPCameraView
//
//  摄像头VIEW，可以查看前／后摄像头，并进行拍照或者二维码的识别
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

/*!
 自定义摄像头的View的用途
 */
typedef enum {
    CPCameraViewOutputTypeUnspecified = 0,  /*!< 未指定用途 */
    CPCameraViewOutputTypePicture,          /*!< 拍照用 */
    CPCameraViewOutputTypeBarCode,          /*!< 识别二维码 */
} CPCameraViewOutputType;

/*!
 *  @author LeiQiao, 16-03-08
 *  @brief 自定义摄像头的代理，不同用途调用不同的回调
 */
@protocol CPCameraViewDelegate <NSObject>

/*!
 *  @author LeiQiao, 16-03-08
 *  @brief 拍照回调
 *  @param picture 拍照的图片
 */
-(void) didTakePicture:(UIImage*)picture;

/*!
 *  @author LeiQiao, 16-03-08
 *  @brief 二维码识别回调
 *  @param barCodeContext 二维码识别出来的内容
 */
-(void) didRecogniedBarCode:(NSString*)barCodeContext;

@end

/*!
 *  @author LeiQiao, 16-03-08
 *  @brief 摄像头VIEW，可以像使用普通的VIEW来使用摄像头VIEW
 */
@interface CPCameraView : UIView

@property(nonatomic, assign) id<CPCameraViewDelegate> delegate;         /*!< 代理方法 */
@property(nonatomic, assign) AVCaptureDevicePosition cameraPosition;    /*!< 前后摄像头 */
@property(nonatomic, assign) CPCameraViewOutputType outputType;         /*!< 输出类型：二维码识别或者拍照 */

/*!
 *  @author LeiQiao, 16-03-08
 *  @brief 拍照，拍照完毕调用delegate的didTakePicture方法
 */
-(void) takePicture;

@end
