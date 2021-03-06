//
//  XYContainerView.m
//  XYContainerView
//
//  Created by aKerdi on 2018/1/12.
//  Copyright © 2018年 XXT. All rights reserved.
//

#import "XYContainerView.h"

static NSString *XYCollectionCellId = @"XYCollectionCellId";
static NSString *XYTableViewContentOffsetKeyPath = @"contentOffset";

@interface XYCollectionCell : UICollectionViewCell

@property (nonatomic, strong) UIView    *subContainerView;

@end

@interface XYContainerView ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *containerView;

@property (nonatomic, strong) UIView    *headContainerView;
@property (nonatomic, strong) UIView    *bannerView;
@property (nonatomic, strong) UIView    *stickView;

@property (nonatomic, assign) NSInteger subContainersCount;
@property (nonatomic, assign) CGFloat   contentOffsetY;
@property (nonatomic, copy) NSArray   <NSNumber *>*nextSectionWillAppeareNotifyStickerMoveArray;

@property (nonatomic, weak) UIScrollView *currentScrollView;

@end

@implementation XYContainerView

- (void)dealloc {
    [self removeCurrentScrollViewObserval];
}

- (void)removeCurrentScrollViewObserval {
    UIScrollView *scrollView = (UIScrollView *)self.currentScrollView;
    [scrollView removeObserver:self forKeyPath:XYTableViewContentOffsetKeyPath];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.subContainersCount = 0;
        _horizonScrollEnable = YES;
        
        [self addSubview:self.containerView];
        self.containerView.frame = self.bounds;
        [self addSubview:self.headContainerView];
    }
    return self;
}

#pragma mark - public

- (void)reloadData {
    //删除所有observal
    [self removeCurrentScrollViewObserval];
    //加载所有所需资源
    self.subContainersCount = [self calculateSubContainersCount];
    UIView *headContainerView = [self getHeadContainerView];
    for (NSInteger i=0; i<self.subContainersCount; i++) {
        UIView *subContainerView = [self.dataSource xyContainerView:self subContainerViewAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        UIScrollView *subContainerScrollView = (UIScrollView *)subContainerView;
        if (![subContainerView isKindOfClass:[UIScrollView class]]) {
            subContainerScrollView = [self.dataSource xyContainerView:self subScrollViewAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        if (i==0) {
            [subContainerScrollView addObserver:self forKeyPath:XYTableViewContentOffsetKeyPath options:NSKeyValueObservingOptionNew context:@selector(reloadData)];
            self.currentScrollView = subContainerScrollView;
            [subContainerScrollView addSubview:self.headContainerView];
            CGRect rect = self.headContainerView.frame;
            rect.origin.y = -CGRectGetHeight(self.headContainerView.frame);
            self.headContainerView.frame = rect;
        }
        UIEdgeInsets insets = subContainerScrollView.contentInset;
        insets.top = CGRectGetHeight(headContainerView.frame);
        subContainerScrollView.contentInset = UIEdgeInsetsMake(insets.top, insets.left, insets.bottom, insets.right);
    }
    if ([self.delegate respondsToSelector:@selector(xyContainerViewShouldNotifyStickerBottomWhenNextSectionWillAppeareWithStickView:)]) {
        self.nextSectionWillAppeareNotifyStickerMoveArray = [self.delegate xyContainerViewShouldNotifyStickerBottomWhenNextSectionWillAppeareWithStickView:self];
    }
    [self.containerView reloadData];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object != self.currentScrollView) {
        return;
    }
    if (context == @selector(reloadData)) {
        CGPoint tableOffset = [[change objectForKey:@"new"] CGPointValue];
        CGFloat tableOffsetY = tableOffset.y;
        
        self.contentOffsetY = tableOffsetY;
        if ([self.delegate respondsToSelector:@selector(xyContainerView:scrollDidScroll:)]) {
            [self.delegate xyContainerView:self scrollDidScroll:object];
        }
        [self notifySticker];
        CGRect rect = self.headContainerView.frame;
        if (tableOffsetY >= -CGRectGetHeight(self.stickView.frame)) {
            if (self.headContainerView.superview==self) {
                return;
            }
            
            rect.origin.y = -CGRectGetHeight(self.headContainerView.frame)+CGRectGetHeight(self.stickView.frame);
            self.headContainerView.frame = rect;
            [self addSubview:self.headContainerView];
        } else {
            if (self.headContainerView.superview==self) {
                rect.origin.y = -CGRectGetHeight(self.headContainerView.frame);
                self.headContainerView.frame = rect;
                [self.currentScrollView addSubview:self.headContainerView];
            }
        }
    }
}

- (void)selectSectionAtIndex:(NSInteger)index {
    [self selectSectionAtIndex:index animated:NO];
}

- (void)selectSectionAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0||index >= self.subContainersCount) {
        return;
    }
    [self scrollViewWillBeginDragging:self.containerView];
    CGPoint contentOffset = self.containerView.contentOffset;
    __weak typeof(self) weakSelf = self;
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            weakSelf.containerView.contentOffset = CGPointMake(index*CGRectGetWidth(self.bounds), contentOffset.y);
        } completion:^(BOOL finished) {
            [weakSelf scrollViewDidEndDecelerating:self.containerView];
        }];
    } else {
        [UIView animateWithDuration:0.001 animations:^{
            weakSelf.containerView.contentOffset = CGPointMake(index*CGRectGetWidth(self.bounds), contentOffset.y);
        } completion:^(BOOL finished) {
            [weakSelf scrollViewDidEndDecelerating:self.containerView];
        }];
    }
}

- (void)setHorizonScrollEnable:(BOOL)horizonScrollEnable {
    if (_horizonScrollEnable == horizonScrollEnable) {
        return;
    }
    _horizonScrollEnable = horizonScrollEnable;
    self.containerView.scrollEnabled = horizonScrollEnable;
}

#pragma mark - private

- (NSInteger)calculateSubContainersCount {
    if ([self.dataSource respondsToSelector:@selector(xyContainerViewWithNumberOfSubContainerView:)]) {
        return [self.dataSource xyContainerViewWithNumberOfSubContainerView:self];
    }
    return 0;
}

- (UIView *)getHeadContainerView {
    [self.bannerView removeFromSuperview];
    [self.stickView removeFromSuperview];
    self.bannerView = nil;
    self.stickView = nil;
    if ([self.delegate respondsToSelector:@selector(xyContainerViewWithBannerView:)]) {
        self.bannerView = [self.delegate xyContainerViewWithBannerView:self];
    }
    if ([self.delegate respondsToSelector:@selector(xyContainerViewWithStickView:)]) {
        self.stickView = [self.delegate xyContainerViewWithStickView:self];
    }
    [self.headContainerView addSubview:self.bannerView];
    CGRect rect = self.stickView.frame;
    rect.origin.y = CGRectGetMaxY(self.bannerView.frame);
    self.stickView.frame = rect;
    [self.headContainerView addSubview:self.stickView];
    CGRect headContainerViewRect = self.headContainerView.frame;
    headContainerViewRect.size.height = CGRectGetHeight(self.bannerView.frame)+CGRectGetHeight(self.stickView.frame);
    self.headContainerView.frame = headContainerViewRect;
    return self.headContainerView;
}

- (void)targetScrollDidScrollInnerFunc {
    UIScrollView *currentScrollView = self.currentScrollView;
    
    for (NSInteger i=0; i<self.subContainersCount; i++) {
        UIScrollView *subScrollView = (UIScrollView *)[self.dataSource xyContainerView:self subScrollViewAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if (subScrollView==currentScrollView) {
            continue;
        }
        //有置顶层 使用置顶层高度
        if ([self.delegate respondsToSelector:@selector(xyContainerViewWithStickView:)]) {
            UIView *stickView = [self.delegate xyContainerViewWithStickView:self];
            CGFloat customViewHeight = CGRectGetHeight(stickView.frame);
            if (customViewHeight > 0) {
                //                currentScrollView 为开始拖拽时当前scrollView,
                //                判断其他当前subScrollView 偏移量是否小于customViewHeight
                if (currentScrollView.contentOffset.y>=-customViewHeight) {
                    if (subScrollView.contentOffset.y<-customViewHeight) {
                        subScrollView.contentOffset = CGPointMake(0, -customViewHeight);
                    }
                    continue;
                } else {
                    subScrollView.contentOffset = currentScrollView.contentOffset;
                }
            }
        } else {
            //无置顶层 查看是否有提供类似置顶层高度方法
            if ([self.delegate respondsToSelector:@selector(xyContainerViewCustomStickViewHeight:)]) {
                CGFloat customViewHeight = [self.delegate xyContainerViewCustomStickViewHeight:self];
                if (customViewHeight > 0) {
                    //                currentScrollView 为开始拖拽时当前scrollView,
                    //                判断其他当前subScrollView 偏移量是否小于customViewHeight
                    if (currentScrollView.contentOffset.y >= -customViewHeight) {
                        if (subScrollView.contentOffset.y < -customViewHeight) {
                            subScrollView.contentOffset = CGPointMake(0, -customViewHeight);
                        }
                        continue;
                    } else {
                        subScrollView.contentOffset = currentScrollView.contentOffset;
                    }
                }
            }
        }
        
//        同上
        if (currentScrollView.contentOffset.y >= -CGRectGetHeight(self.stickView.frame)) {
            if (subScrollView.contentOffset.y < -CGRectGetHeight(self.stickView.frame)) {
                subScrollView.contentOffset = CGPointMake(0, -CGRectGetHeight(self.stickView.frame));
            }
            continue;
        } else {
            subScrollView.contentOffset = currentScrollView.contentOffset;
        }
    }
}

#pragma mark - UICollectinoViewDataSource

- (void)freshHeadContainerViewFrame {
    CGFloat maxTop = MAX(-(CGRectGetHeight(self.headContainerView.frame)+self.currentScrollView.contentOffset.y), -(CGRectGetHeight(self.headContainerView.frame)-CGRectGetHeight(self.stickView.frame)));
    CGRect rect = self.headContainerView.frame;
    rect.origin.y = maxTop;
    self.headContainerView.frame = rect;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.currentScrollView.userInteractionEnabled = NO;
    [self freshHeadContainerViewFrame];
    [self addSubview:self.headContainerView];
    [self targetScrollDidScrollInnerFunc];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect rect = self.headContainerView.frame;
    rect.origin.x = 0;
    self.headContainerView.frame = rect;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    self.currentScrollView.userInteractionEnabled = YES;
    CGPoint targetOffset = *targetContentOffset;
    CGFloat offsetX = targetOffset.x;
    NSUInteger index = offsetX / CGRectGetWidth(self.bounds);
    if ([self.delegate respondsToSelector:@selector(xyContainerView:didSelectContentAtIndex:)]) {
        [self.delegate xyContainerView:self didSelectContentAtIndex:index];
    }
    [self notifySticker];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.currentScrollView.userInteractionEnabled = YES;
    CGPoint offsetP = scrollView.contentOffset;
    NSInteger index = offsetP.x/CGRectGetWidth(self.bounds);
    [self.currentScrollView removeObserver:self forKeyPath:XYTableViewContentOffsetKeyPath];
    
    self.currentScrollView = [self.dataSource xyContainerView:self subScrollViewAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [self.currentScrollView addObserver:self forKeyPath:XYTableViewContentOffsetKeyPath options:NSKeyValueObservingOptionNew context:@selector(reloadData)];
    [self freshHeadContainerViewFrame];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.subContainersCount;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XYCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:XYCollectionCellId forIndexPath:indexPath];
    UIView *subContainerView = [self.dataSource xyContainerView:self subContainerViewAtIndexPath:indexPath];
    if (cell.subContainerView != subContainerView) {
        [cell addSubview:subContainerView];
        cell.subContainerView = subContainerView;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.nextSectionWillAppeareNotifyStickerMoveArray.count) {
        for (NSNumber *number in self.nextSectionWillAppeareNotifyStickerMoveArray) {
            if ([number integerValue] == indexPath.row) {
                [self notifyStickerWithIndex:indexPath.row];
                return;
            }
        }
    }
}


#pragma mark - Accessory & helper

- (void)notifySticker {
    CGPoint offsetP = self.containerView.contentOffset;
    NSInteger index = offsetP.x/CGRectGetWidth(self.bounds);
    [self notifyStickerWithIndex:index];
    
}

- (void)notifyStickerWithIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(xyContainer:currentIndex:stickerBottom:)]) {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        CGRect stickViewRect = [self.stickView.superview convertRect:self.stickView.frame toView:window];
        [self.delegate xyContainer:self currentIndex:index stickerBottom:CGRectGetMaxY(stickViewRect)];
    }
}

- (UIView *)headContainerView {
    if (!_headContainerView) {
        _headContainerView = [UIView new];
        _headContainerView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), 0);
    }
    return _headContainerView;
}

- (UICollectionView *)containerView {
    if (!_containerView) {
        UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.sectionInset = UIEdgeInsetsZero;
        flowLayout.minimumLineSpacing = 0.0000001;
        flowLayout.minimumInteritemSpacing = 0.0000001;
        flowLayout.itemSize = CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.frame));
        _containerView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
        _containerView.delegate = self;
        _containerView.dataSource = self;
        _containerView.pagingEnabled = YES;
        _containerView.showsVerticalScrollIndicator = NO;
        _containerView.showsHorizontalScrollIndicator = NO;
        _containerView.bounces = NO;
        _containerView.backgroundColor = [UIColor clearColor];
        [_containerView registerClass:[XYCollectionCell class] forCellWithReuseIdentifier:XYCollectionCellId];
    }
    return _containerView;
}
@end

@implementation XYCollectionCell

@end
