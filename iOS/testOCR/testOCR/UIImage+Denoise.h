//
//  UIImage+Denoise.h
//

#import <UIKit/UIKit.h>

extern const CGFloat kDefaultDenoiseWidth;
extern const CGFloat kDefaultDenoiseHeight;
extern const CGFloat kDefaultDenoisePercent;

@interface UIImage (Denoise)

+(UIImage*) imageNegate:(UIImage*)image;
+(UIImage*) imageDenoise:(UIImage*)image;
+(UIImage*) imageDenoise:(UIImage*)image width:(CGFloat)width height:(CGFloat)height percent:(CGFloat)percent;

@end
