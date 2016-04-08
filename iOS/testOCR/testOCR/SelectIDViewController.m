//
//  SelectIDViewController.m
//  testOCR
//
//  Created by lei.qiao on 16/4/7.
//  Copyright © 2016年 LeiQiao. All rights reserved.
//

#import "SelectIDViewController.h"
#import "AddIDViewController.h"

NSString *const kSelectIDNotification = @"kSelectIDNotification";

@implementation SelectIDViewController {
    UINavigationItem* _barItem;
    
    UITableView* _tableView;
    NSMutableArray* _idDatas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationBar* bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    _barItem = [[UINavigationItem alloc] initWithTitle:@"选择号码"];
    [bar pushNavigationItem:_barItem animated:NO];
    [self.view addSubview:bar];
    
    [self changeToSelect];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height-64)];
    _tableView.delegate = (id<UITableViewDelegate>)self;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    [self.view addSubview:_tableView];
    
    [self load];
    [_tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDidAdd:)
                                                 name:kAddIDNotification
                                               object:nil];
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) changeToEdit
{
    _barItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(onQuitEdit:)];
    _barItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(onAdd:)];
}

-(void) changeToSelect
{
    _barItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"编辑"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(onEdit:)];
    _barItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(onAdd:)];
}

-(void) onAdd:(id)sender
{
    AddIDViewController* vc = [[AddIDViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

-(void) onEdit:(id)sender
{
    [_tableView setEditing:YES animated:YES];
    [self changeToEdit];
}

-(void) onQuitEdit:(id)sender
{
    [_tableView setEditing:NO animated:YES];
    [self changeToSelect];
}

-(void) onDidAdd:(NSNotification*)notify
{
    [_idDatas insertObject:notify.object atIndex:0];
    [self save];
    [_tableView reloadData];
}

#pragma mark
#pragma mark 数据存储读取

-(void) load
{
    _idDatas = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"ids"]];
    if( !_idDatas )
    {
        _idDatas = [NSMutableArray array];
    }
}

-(void) save
{
    [[NSUserDefaults standardUserDefaults] setObject:_idDatas forKey:@"ids"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark
#pragma mark UITableViewDelegate && UITableViewDataSource

-(NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return _idDatas.count;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                   reuseIdentifier:nil];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [[_idDatas objectAtIndex:indexPath.row] objectForKey:@"name"];
    cell.detailTextLabel.text = [[_idDatas objectAtIndex:indexPath.row] objectForKey:@"id"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( UITableViewCellEditingStyleDelete == editingStyle )
    {
        [_idDatas removeObjectAtIndex:indexPath.row];
        [self save];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* idData = [_idDatas objectAtIndex:indexPath.row];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSelectIDNotification object:idData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
