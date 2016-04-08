//
//  UIImage+Denoise.m
//

#import "UIImage+Denoise.h"
#import <QuartzCore/QuartzCore.h>

const CGFloat kDefaultDenoiseWidth = 25;
const CGFloat kDefaultDenoiseHeight = 25;
const CGFloat kDefaultDenoisePercent = 0.15;

#define     PIXEL_R(__X, __Y)  (imageData[((bytesPerRow * __Y) + __X * bytesPerPixel)])
#define     PIXEL_G(__X, __Y)  (imageData[((bytesPerRow * __Y) + __X * bytesPerPixel)+1])
#define     PIXEL_B(__X, __Y)  (imageData[((bytesPerRow * __Y) + __X * bytesPerPixel)+2])
#define     PIXEL_A(__X, __Y)  (imageData[((bytesPerRow * __Y) + __X * bytesPerPixel)+3])

void UIImageDenoisePiece(unsigned char* imageData, NSUInteger startX, NSUInteger startY, NSUInteger pieceWidth, NSUInteger pieceHeight, CGFloat boostPercent, NSUInteger bytesPerRow, NSUInteger bytesPerPixel)
{
    CGFloat avgR = 0;
    CGFloat avgG = 0;
    CGFloat avgB = 0;
    
    /*---------- 计算去噪块的平均值 ----------*/
    for( NSUInteger x=startX; x<startX+pieceWidth; x++ )
    {
        for( NSUInteger y=startY; y<startY+pieceHeight; y++ )
        {
            avgR += PIXEL_R(x, y);
            avgG += PIXEL_G(x, y);
            avgB += PIXEL_B(x, y);
        }
    }
    
    avgR /= pieceWidth * pieceHeight;
    avgG /= pieceWidth * pieceHeight;
    avgB /= pieceWidth * pieceHeight;
    
    // 平均值加增益比
    avgR *= (1+boostPercent);
    avgG *= (1+boostPercent);
    avgB *= (1+boostPercent);
    
    NSUInteger avgRGBA = (((NSUInteger)avgR & 0xFF) << 24) | (((NSUInteger)avgG & 0xFF) << 16) | (((NSUInteger)avgB & 0xFF) << 8);
    
    /*---------- 对每个像素点跟平均值进行比较，如果大于平均值则为黑，否则为白 ----------*/
    for( NSUInteger y=startY; y<startY+pieceHeight; y++ )
    {
        for( NSUInteger x=startX; x<startX+pieceWidth; x++ )
        {
            NSUInteger pRGBA = (((NSUInteger)PIXEL_R(x, y) & 0xFF) << 24) | (((NSUInteger)PIXEL_G(x, y) & 0xFF) << 16) | (((NSUInteger)PIXEL_B(x, y) & 0xFF) << 8);
            
            if( pRGBA > avgRGBA )
            {
                PIXEL_R(x, y) = 0x00;
                PIXEL_G(x, y) = 0x00;
                PIXEL_B(x, y) = 0x00;
                PIXEL_A(x, y) = 0xFF;
            }
            else
            {
                PIXEL_R(x, y) = 0xFF;
                PIXEL_G(x, y) = 0xFF;
                PIXEL_B(x, y) = 0xFF;
                PIXEL_A(x, y) = 0xFF;
            }
//            // Red
//            if( PIXEL_R(x, y) > avgR )
//            {
//                PIXEL_R(x, y) = 0x0;
//            }
//            else
//            {
//                PIXEL_R(x, y) = 0xFF;
//            }
//            
//            // Green
//            if( PIXEL_G(x, y) > avgR )
//            {
//                PIXEL_G(x, y) = 0x0;
//            }
//            else
//            {
//                PIXEL_G(x, y) = 0xFF;
//            }
//            
//            // Blue
//            if( PIXEL_B(x, y) > avgR )
//            {
//                PIXEL_B(x, y) = 0x0;
//            }
//            else
//            {
//                PIXEL_B(x, y) = 0xFF;
//            }
        }
    }
}

@implementation UIImage(Denoise)

+(UIImage*) imageNegate:(UIImage*)image
{
    /*---------- 将图像信息读取到内存中 ----------*/
    CGImageRef imageRef = [image CGImage];
    NSUInteger imageWidth = CGImageGetWidth(imageRef);
    NSUInteger imageHeight = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char* imageData = (unsigned char*) calloc(imageHeight * imageWidth * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * imageWidth;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(imageData, imageWidth, imageHeight,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), imageRef);
    
    // 每个像素取反
    for( int y=0; y<imageHeight; y++ )
    {
        for( int x=0; x<imageWidth; x++ )
        {
            PIXEL_R(x, y) = ~PIXEL_R(x, y);
            PIXEL_G(x, y) = ~PIXEL_G(x, y);
            PIXEL_B(x, y) = ~PIXEL_B(x, y);
        }
    }
    
    // 转换成图片
    CGImageRef outputImageRef = CGBitmapContextCreateImage(context);
    image = [UIImage imageWithCGImage:outputImageRef];
    
    // 删除内存中的图像数据
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(imageData);
    
    return image;
}

+(UIImage*) imageDenoise:(UIImage*)image
{
    return [[self class] imageDenoise:image
                                width:kDefaultDenoiseWidth
                               height:kDefaultDenoiseHeight
                              percent:kDefaultDenoisePercent];
}

+(UIImage*) imageDenoise:(UIImage*)image width:(CGFloat)width height:(CGFloat)height percent:(CGFloat)percent
{
    /*---------- 将图像信息读取到内存中 ----------*/
    CGImageRef imageRef = [image CGImage];
    NSUInteger imageWidth = CGImageGetWidth(imageRef);
    NSUInteger imageHeight = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char* imageData = (unsigned char*) calloc(imageHeight * imageWidth * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * imageWidth;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(imageData, imageWidth, imageHeight,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), imageRef);
    
    // 计算小方块的个数
    NSUInteger pieceCol = (imageWidth / (NSUInteger)width) + (((imageWidth % (NSUInteger)width) > 0) ? 1 : 0);
    NSUInteger pieceRow = (imageHeight / (NSUInteger)height) + (((imageHeight % (NSUInteger)height) > 0) ? 1 : 0);
    
    for( int y=0; y<pieceRow; y++ )
    {
        for( int x=0; x<pieceCol; x++ )
        {
            NSUInteger startX = x * width;
            NSUInteger startY = y * height;
            NSUInteger pieceWidth = (width > (imageWidth - startX)) ? (imageWidth - startX) : width;
            NSUInteger pieceHeight = (height > (imageHeight - startY)) ? (imageHeight - startY) : height;
            
            UIImageDenoisePiece(imageData, startX, startY, pieceWidth, pieceHeight, percent, bytesPerRow, bytesPerPixel);
        }
    }
    
    // 转换成图片
    CGImageRef outputImageRef = CGBitmapContextCreateImage(context);
    image = [UIImage imageWithCGImage:outputImageRef];
    
    // 删除内存中的图像数据
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(imageData);
    
    return image;
}

@end
