//
//  RecognizeViewController.m
//  testOCR
//
//  Created by lei.qiao on 16/4/7.
//  Copyright © 2016年 LeiQiao. All rights reserved.
//

#import "RecognizeViewController.h"
#import "UIImage-Extensions.h"
#import "TesseractOCR.h"

@implementation RecognizeViewController {
    UITextField* _prefixTextField;
    UITextField* _birthdayTextField;
    UITextField* _suffixTextField;
    
    UIImage* _idCardImage;
    
    G8Tesseract* _tesseract;
}

-(instancetype) initWithIDCard:(UIImage*)idCardImage
{
    if( self = [super init] )
    {
        _idCardImage = idCardImage;
    }
    return self;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UINavigationBar* navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
    [self.view addSubview:navBar];
    
    UINavigationItem* navItem = [[UINavigationItem alloc] initWithTitle:@"识别结果"];
    navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(onCancel:)];
    navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:self action:@selector(onOK:)];
    
    [navBar pushNavigationItem:navItem animated:NO];
    
    CGFloat x = (self.view.frame.size.width-100-150-80-40)/2;
    
    _prefixTextField = [[UITextField alloc] initWithFrame:CGRectMake(x, 60, 100, 35)];
    _prefixTextField.keyboardType = UIKeyboardTypeNumberPad;
    _prefixTextField.borderStyle = UITextBorderStyleRoundedRect;
    _prefixTextField.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_prefixTextField];
    
    _birthdayTextField = [[UITextField alloc] initWithFrame:CGRectMake(120+x, 60, 150, 35)];
    _birthdayTextField.keyboardType = UIKeyboardTypeNumberPad;
    _birthdayTextField.borderStyle = UITextBorderStyleRoundedRect;
    _birthdayTextField.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_birthdayTextField];
    
    _suffixTextField = [[UITextField alloc] initWithFrame:CGRectMake(290+x, 60, 80, 35)];
    _suffixTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _suffixTextField.borderStyle = UITextBorderStyleRoundedRect;
    _suffixTextField.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_suffixTextField];
    
    _tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    _tesseract.charWhitelist = @"0123456789";
    
//    [self savePictureToDocument:picture];
//    UIImageWriteToSavedPhotosAlbum(picture, nil, nil, nil);

    [self doRecognize:_idCardImage];
}

-(void) doRecognize:(UIImage*)image
{
    _tesseract.image = image;
    
    [_tesseract recognize];
    
    NSString* recognizedText = _tesseract.recognizedText;
    NSLog(@"%@", recognizedText);
    
//    NSArray *characterBoxes = [_tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelSymbol];
//    UIImage *imageWithBlocks = [_tesseract imageWithBlocks:characterBoxes drawText:YES thresholded:YES];
//    
//    _imageView.image = [imageWithBlocks imageRotatedByDegrees:90];
    
    NSRange range = [recognizedText rangeOfString:@"\\d\\{17\\}[0-9xX]"];
    if( range.location == NSNotFound ) return;
}

-(void) onCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) onOK:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
