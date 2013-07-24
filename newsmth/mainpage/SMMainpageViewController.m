//
//  SMMainpageViewController.m
//  newsmth
//
//  Created by Maxwin on 13-5-29.
//  Copyright (c) 2013年 nju. All rights reserved.
//

#import "SMMainpageViewController.h"
#import "XPullRefreshTableView.h"
#import "SMPostGroupViewController.h"
#import "SMPostViewController.h"
#import "SMMainpageCell.h"
#import "SMMainPage.h"
#import "SMSection.h"
#import "SMPost.h"

static SMMainpageViewController *_instance;

@interface SMMainpageViewController ()<UITableViewDataSource, UITableViewDelegate, SMWebLoaderOperationDelegate, XPullRefreshTableViewDelegate>
@property (weak, nonatomic) IBOutlet XPullRefreshTableView *tableView;

@property (strong, nonatomic) SMWebLoaderOperation *op;

@property (strong, nonatomic) NSArray *sections;
@end

@implementation SMMainpageViewController

+ (SMMainpageViewController *)instance
{
    if (_instance == nil) {
        _instance = [[SMMainpageViewController alloc] init];
    }
    return _instance;
}
- (id)init
{
    if (_instance == nil) {
        _instance = [super initWithNibName:@"SMMainpageViewController" bundle:nil];
    }
    return _instance;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"首页导读";
    _tableView.xdelegate = self;
    [_tableView beginRefreshing];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
    if (indexPath) {
        [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)setSections:(NSArray *)sections
{
    _sections = sections;
    [self.tableView reloadData];
}

- (void)dealloc
{
    [_op cancel];
}

- (void)loadData:(BOOL)more
{
    _op = [[SMWebLoaderOperation alloc] init];
    _op.delegate = self;
    [_op loadUrl:@"http://www.newsmth.net/mainpage.html" withParser:@"mainpage"];
}
#pragma mark - XPullRefreshTableViewDelegate
- (void)tableViewDoRefresh:(XPullRefreshTableView *)tableView
{
    [self loadData:NO];
    [SMUtils trackEventWithCategory:@"mainpage" action:@"refresh" label:nil];
}

#pragma mark - UITableViewDataSource/Delegate
- (SMPost *)postAtIndexPath:(NSIndexPath *)indexPath
{
    SMSection *secdata = _sections[indexPath.section];
    return secdata.posts[indexPath.row];   
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    SMSection *secdata = _sections[section];
    return secdata.posts.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMPost *post = [self postAtIndexPath:indexPath];
    return [SMMainpageCell cellHeight:post];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    SMSection *secdata = _sections[section];
    return secdata.sectionTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellid = @"cell";
    SMMainpageCell *cell = (SMMainpageCell *)[tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [[SMMainpageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid];
    }
    
    cell.post = [self postAtIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMSection *secdata = _sections[indexPath.section];
    SMPost *post = secdata.posts[indexPath.row];
    
//    SMPostGroupViewController *vc = [[SMPostGroupViewController alloc] init];
    SMPostViewController *vc = [[SMPostViewController alloc] init];
    vc.board = post.board;
    vc.gid = post.gid;
    [self.navigationController pushViewController:vc animated:YES];
    
    [SMUtils trackEventWithCategory:@"mainpage" action:@"row_click" label:
     [NSString stringWithFormat:@"%d-%d", indexPath.section, indexPath.row]
     ];
}

#pragma mark - SMWebLoaderOperationDelegate
- (void)webLoaderOperationFinished:(SMWebLoaderOperation *)opt
{
    [_tableView endRefreshing:YES];
    SMMainPage *data = opt.data;
    self.sections = data.sections;
}

- (void)webLoaderOperationFail:(SMWebLoaderOperation *)opt error:(SMMessage *)error
{
    [_tableView endRefreshing:NO];
    [self toast:error.message];
}

@end
