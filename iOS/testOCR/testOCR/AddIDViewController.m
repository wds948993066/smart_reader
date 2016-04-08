//
//  AddIDViewController.m
//  testOCR
//
//  Created by lei.qiao on 16/4/7.
//  Copyright © 2016年 LeiQiao. All rights reserved.
//

#import "AddIDViewController.h"
#import "HUD.h"

NSString *const kAddIDNotification = @"kAddIDNotification";

@implementation AddIDViewController {
    UITextField* _name;
    UITextField* _idnumber;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UINavigationBar* bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    UINavigationItem* barItem = [[UINavigationItem alloc] initWithTitle:@"选择号码"];
    barItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(onCancel:)];
    barItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(onOK:)];
    [bar pushNavigationItem:barItem animated:NO];
    [self.view addSubview:bar];
    
    _name = [[UITextField alloc] initWithFrame:CGRectMake(20, 84, self.view.frame.size.width-40, 40)];
    _name.borderStyle = UITextBorderStyleRoundedRect;
    _name.placeholder = @"请输入身份证名称";
    _name.keyboardType = UIKeyboardTypeDefault;
    [self.view addSubview:_name];
    
    _idnumber = [[UITextField alloc] initWithFrame:CGRectMake(20, 144, self.view.frame.size.width-40, 40)];
    _idnumber.borderStyle = UITextBorderStyleRoundedRect;
    _idnumber.placeholder = @"请输入身份证号码";
    _idnumber.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    [self.view addSubview:_idnumber];
    
    [_name becomeFirstResponder];
}

-(void) onCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) onOK:(id)sender
{
    if( _name.text.length == 0 )
    {
        popError(@"请输入名称");
        [_name becomeFirstResponder];
        return;
    }
    if( _idnumber.text.length == 0 )
    {
        popError(@"请输入身份证号");
        [_idnumber becomeFirstResponder];
        return;
    }
    
    NSDictionary* idData = @{@"name":_name.text, @"id":_idnumber.text};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddIDNotification object:idData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
