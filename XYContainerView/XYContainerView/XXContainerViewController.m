//
//  ViewController.m
//  XYContainerView
//
//  Created by aKerdi on 2018/1/12.
//  Copyright © 2018年 XXT. All rights reserved.
//

#import "XXContainerViewController.h"

#import "XXContainerView.h"

@interface XXContainerViewController ()<XXContainerViewDelegate, XXContainerViewDataSource, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) XXContainerView *containerView;

@property (nonatomic, strong) NSArray<UIScrollView *> *scrollViewArray;

@end

@implementation XXContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.containerView = [[XXContainerView alloc] initWithFrame:self.view.bounds];
    self.containerView.delegate = self;
    self.containerView.dataSource = self;
    [self.view addSubview:self.containerView];
    
    [self dispatchTimeCreateSubView];
}

- (void)dispatchTimeCreateSubView {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:2];
        for (NSInteger i=0; i<2; i++) {
            UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
            tableView.dataSource = self;
            tableView.delegate = self;
            tableView.tag = 100+i;
            [arr addObject:tableView];
        }
        self.scrollViewArray = arr;
        [self.containerView reloadData];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 30;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%ld %ld",(long)tableView.tag, (long)indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.000001;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.000001;
}

#pragma mark - XYContainerDataSource &

- (NSInteger)xxContainerViewWithNumberOfSubContainerView:(XXContainerView *)containerView {
    return self.scrollViewArray.count;
}

- (UIView *)xxContainerView:(XXContainerView *)containerView subContainerViewAtIndexPath:(NSIndexPath *)indexPath {
    return [self.scrollViewArray objectAtIndex:indexPath.row];
}

- (UIView *)xxContainerViewWithBannerView:(XXContainerView *)containerView {
    UIView *bannerView = [UIView new];
    bannerView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 120);
    bannerView.backgroundColor = [UIColor greenColor];
    return bannerView;
}

- (UIView *)xxContainerViewWithStickView:(XXContainerView *)containerView {
    UIView *stickView = [UIView new];
    stickView.backgroundColor = [UIColor yellowColor];
    stickView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 80);
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(10, 10, 50, 50);
    [stickView addSubview:button];
    button.backgroundColor = [UIColor cyanColor];
    [button addTarget:self action:@selector(gogogogo:) forControlEvents:UIControlEventTouchUpInside];
    return stickView;
}

static NSInteger _count = 0;
- (void)gogogogo:(UIButton *)sender {
    _count ++;
    NSLog(@"1111111111");
    [sender setTitle:[@(_count) stringValue] forState:UIControlStateNormal];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
