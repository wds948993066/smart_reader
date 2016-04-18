
#import "Base64.h"

#define     LocalStr_None           @""


@implementation Base64


#pragma mark - Base64 encoding

/*!
 *  @author chunying.jia, 16-04-08
 *
 *  @brief: base64 string decode to NSData
 *  @param string: base64 String
 *  @return: decoded NSData
 */
+ (NSData *)dataWithBase64EncodedString:(NSString *)string
{
    return [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

/*!
 *  @author chunying.jia, 16-04-08
 *
 *  @brief: NSData encode to Base64 String
 *  @param data: NSData
 *  @return: Encoded Base64 String
 */
+ (NSString *)base64EncodedStringFrom:(NSData *)data
{
    return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];;
}



#pragma mark -  Base64

+ (NSString *)base64StringFromText:(NSString *)text
{
    if (text && ![text isEqualToString:LocalStr_None]) {
        NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
        return [self base64EncodedStringFrom:data];
    }
    else {
        return LocalStr_None;
    }
}

+ (NSString *)textFromBase64String:(NSString *)base64
{
    if (base64 && ![base64 isEqualToString:LocalStr_None]) {
        NSData *data = [self dataWithBase64EncodedString:base64];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    else {
        return LocalStr_None;
    }
}



@end
