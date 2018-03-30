//
//  ASCalendarView.m
//  AshishCalendarApp
//
//  Created by Ashish Singh on 1/26/18.
//  Copyright © 2018 Ashish. All rights reserved.
//

#import "ASCalendarView.h"
#import "NSDate+AS_DateHelpers.h"
#import "ASCalendarDayCollectionViewCell.h"
#import "ASCalendarWeekdayView.h"
#import "UIColor+AS.h"
#import "ASCalendarFooterCollectionReusableView.h"
#import "ASCalendarSectionHeaderView.h"

#define DAYS_IN_WEEK 7
#define MONTHS_IN_YEAR 12

static CGFloat const kASCollectionViewItemSpacing = 0.f;
static CGFloat const kASCollectionViewLineSpacing = 0.f;
static CGFloat const kASCollectionViewHeaderSectionSpacing = 40.f;
static CGFloat const kASOverlayViewOpacity = .8f;

@interface ASCalendarView() <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, ASCalendarDateOperationDataSource>
@property (nonatomic, strong) UICollectionView* collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout* flowLayout;
@property (nonatomic, strong) NSDate* currentDate;
@property (nonatomic, assign) CGFloat startOffsetY;
@property (nonatomic, strong) ASCalendarWeekdayView *weekdayView;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) NSArray<UILabel *>* overlayLabels;
@property (nonatomic, strong) UIView* overlayView;
@end
@implementation ASCalendarView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _weekdayView = [[ASCalendarWeekdayView alloc] initWithFrame:CGRectZero];
    [self addSubview:_weekdayView];
    
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.minimumInteritemSpacing  = kASCollectionViewItemSpacing;
    layout.minimumLineSpacing       = kASCollectionViewLineSpacing;
    self.flowLayout = layout;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor as_lightGrayColor];
    _collectionView.dataSource = self;
    _collectionView.delegate   = self;
    _collectionView.allowsMultipleSelection = NO;
    [self addSubview:_collectionView];
    
    [_collectionView registerClass:[ASCalendarDayCollectionViewCell class]    forCellWithReuseIdentifier:kASCalendarDayCollectionViewCellIdentifier];
    [_collectionView registerClass:[ASCalendarFooterCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kASCalendarFooterReusableViewIdentifier];
    [_collectionView registerClass:[ASCalendarSectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kASCalendarSectionHeaderViewIdentifier];
    
    _separatorView = [UIView new];
    _separatorView.backgroundColor = [UIColor as_darkGrayColor];
    [self addSubview:_separatorView];
    
    //Default Configuration
    _currentDate = [NSDate date];
    _startDate      =  [NSDate defaultStartDate];
    _startDate = [self.startDate dateByAddingDays:-[self offsetIndex]];
    _selectedDate   = _currentDate;
    _endDate        = [NSDate defaultEndDate];
    _highlightColor = [UIColor redColor];
    _indicatorColor = [UIColor lightGrayColor];
    _dateTextColor  = [UIColor blackColor];
    _startOffsetY = CGFLOAT_MIN;
    
    // Overlay view to show month and year for current visible calendar date when user scrolls.
    _overlayView = [UIView new];
    self.clipsToBounds = NO;
    _overlayView.userInteractionEnabled = NO;
    _overlayView.frame = CGRectMake(0, 0, self.collectionView.frame.size.width, self.collectionView.contentSize.height);
    // Set Overlay view bounds to same as collectionview.
    [_collectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior context:NULL];
    [_collectionView addSubview:_overlayView];
    _overlayView.alpha = 0;
    _overlayView.backgroundColor = [UIColor whiteColor];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.weekdayView.frame = CGRectMake(0, 0, self.bounds.size.width, WEEKDAY_VIEW_HEIGHT);
    self.collectionView.frame = CGRectMake([self marginForCollectionView], WEEKDAY_VIEW_HEIGHT, self.bounds.size.width - [self marginForCollectionView] * 2, self.bounds.size.height - WEEKDAY_VIEW_HEIGHT);
    self.separatorView.frame = CGRectMake(0, CGRectGetMaxY(self.weekdayView.frame), self.bounds.size.width, 1.0f);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.startDate numberOfDaysTillDate:self.endDate] + 1;
}

#pragma mark - UICollectionViewDelegate
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ASCalendarDayCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kASCalendarDayCollectionViewCellIdentifier forIndexPath:indexPath];
    ASCalendarCellViewModel *viewModel = [[ASCalendarCellViewModel alloc] initWithCalendarDateSource:self indexPath:indexPath];
    [cell configureCellWith:viewModel];
    if (viewModel.selectedItem) {
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    /**
     Sometimes the cellForRowatIndexPath method is not called when scrollview scrolled by delegate method call,
     issue happens in rare cases. Below logic ensures that there is proper interaction between Calendar and
     Agenda Views.
     */
    ASCalendarCellViewModel *viewModel = [[ASCalendarCellViewModel alloc] initWithCalendarDateSource:self indexPath:indexPath];
    if (viewModel.selectedItem) {
        cell.selected = YES;
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view;
    if (kind == UICollectionElementKindSectionFooter) {
        ASCalendarFooterCollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kASCalendarFooterReusableViewIdentifier forIndexPath:indexPath];
        view = footerView;
    }
    else if (kind == UICollectionElementKindSectionHeader) {
        ASCalendarSectionHeaderView *sectionHeaderView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kASCalendarSectionHeaderViewIdentifier forIndexPath:indexPath];

        [sectionHeaderView setHeaderText:@""];
        view = sectionHeaderView;
    }
    return view;
}

/**
 Move CollectionView one row down if the first visible row is selected and one row up if the last
 visisble row is selected.
 Move one row up if the selected date is greater than the last selected date.
 Move one row down if the selected date is lesser than the last selected date.
 */
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // Return if indexPath is lesser than start index.
    if (indexPath.item < [self offsetIndex]) {
        return;
    }
    // Rect that has the top visible rows.
    CGRect visibleRect = CGRectMake(0, collectionView.contentOffset.y, collectionView.bounds.size.width, 40);
    CGPoint visiblePoint = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect));
    // One visible point in the top visible row.
    NSIndexPath *visibleIndexPath = [self.collectionView indexPathForItemAtPoint:visiblePoint];
    // Rect that has the current bottom visible rows.
    CGRect bottomVisibleRect = CGRectMake(0, collectionView.contentOffset.y + collectionView.bounds.size.height - 30, collectionView.bounds.size.width, 30);
    // One visible point in the last visible row.
    CGPoint bottomVisiblePoint = CGPointMake(CGRectGetMidX(bottomVisibleRect), CGRectGetMidY(bottomVisibleRect));
    NSIndexPath *bottomVisibleIndexPath = [self.collectionView indexPathForItemAtPoint:bottomVisiblePoint];
    // Attributes for one of the last visible row's indexPaths.
    UICollectionViewLayoutAttributes* bottomSelectedAttrs = [self.collectionView layoutAttributesForItemAtIndexPath:bottomVisibleIndexPath];
    // Attributes for one of the top visible row's indexPaths.
    UICollectionViewLayoutAttributes* topSelectedAttrs = [self.collectionView layoutAttributesForItemAtIndexPath:visibleIndexPath];
    // Attributes for one of the last selected indexPath.
    UICollectionViewLayoutAttributes* lastSelectedAttrs = [self.collectionView layoutAttributesForItemAtIndexPath:[self indexPathForDate:self.selectedDate]];
    UICollectionViewLayoutAttributes* currentSelectedAttrs = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    self.selectedDate = [self dateAtIndexPath:indexPath];
    if (currentSelectedAttrs.frame.origin.y == bottomSelectedAttrs.frame.origin.y) {
        [self scrollToSectionHeader:visibleIndexPath.item + DAYS_IN_WEEK animated:YES];
    }
    else if (currentSelectedAttrs.frame.origin.y == topSelectedAttrs.frame.origin.y) {
        [self scrollToSectionHeader:visibleIndexPath.item - DAYS_IN_WEEK animated:YES];
    }
    else if (currentSelectedAttrs.frame.origin.y != lastSelectedAttrs.frame.origin.y) {
        if (currentSelectedAttrs.frame.origin.y > lastSelectedAttrs.frame.origin.y) {
            [self scrollToSectionHeader:visibleIndexPath.item + DAYS_IN_WEEK animated:YES];
        }
        else {
            [self scrollToSectionHeader:visibleIndexPath.item - DAYS_IN_WEEK animated:YES];
        }
    }
    if ([_delegate respondsToSelector:@selector(calendarView:didSelectDate:)]) {
        [_delegate calendarView:self didSelectDate:self.selectedDate];
    }
}

#pragma mark - UICollectionViewFlowLayoutDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellWidth = [self cellWidth];
    CGFloat cellHeight = cellWidth;
    return CGSizeMake(cellWidth, cellHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGFloat boundsWidth = collectionView.bounds.size.width;
    return CGSizeMake(boundsWidth, kASCollectionViewHeaderSectionSpacing);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(CGRectGetWidth(self.bounds), 0);
}



#pragma mark UIScrollViewDelegate
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSIndexPath* indexpath = [self.collectionView indexPathForItemAtPoint:*targetContentOffset];
    UICollectionViewLayoutAttributes* attrs = [self.collectionView layoutAttributesForItemAtIndexPath:indexpath];
    targetContentOffset->y = attrs.frame.origin.y;
}

/**
 Add overlay labels on collectionview to show current visible Months. Show overlay labels only when user is
 scrolling or scrolled the ScrollView, or when it's scrolled due to interaction with Agenda View.
 One overlay label shows the month and year for the current top visible row's date.
 The second overlay label shows the month and year for current date =  top visible row's date + 1 month
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect visibleRect = CGRectMake(0, self.collectionView.contentOffset.y, self.collectionView.bounds.size.width, 50);
    CGPoint visiblePoint = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect));
    NSIndexPath *visibleIndexPath = [self.collectionView indexPathForItemAtPoint:visiblePoint];
    NSDate* topDate = [[self dateAtIndexPath:visibleIndexPath] firstDayOfMonth];
    NSDate* lastDate = [[self dateAtIndexPath:visibleIndexPath] lastDayOfMonth];
    [self updateOverlayLabelForIndex:0 firstDate:topDate endDate:lastDate];
    topDate = [lastDate dateByAddingDays:1];
    lastDate = [topDate lastDayOfMonth];
    [self updateOverlayLabelForIndex:1 firstDate:topDate endDate:lastDate];
    self.collectionView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3f];
    if (scrollView.isTracking) {
        [self.delegate calendarView:self scrolledToSectionOfDifferentNumberOfRows:5];
        [self hideOverlayView:NO];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self hideOverlayView:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self hideOverlayView:YES];
    }
}

- (void)hideOverlayView:(BOOL)hide {
    [UIView animateWithDuration:0.5f animations:^{
        self.overlayView.alpha = hide ? 0 : kASOverlayViewOpacity;
    }];
}

//ColletionView DataSource Helpers
- (CGFloat)cellWidth {
    CGFloat boundsWidth = self.collectionView.bounds.size.width;
    return floor(boundsWidth / DAYS_IN_WEEK) - kASCollectionViewItemSpacing;
}

#pragma mark ASCalendarDateOperationDataSource
- (BOOL)shouldShowIndicatorForDate:(NSDate *)date {
    if ([self.delegate respondsToSelector:@selector(calendarView:shouldShowIndicatorForDate:)]) {
        return [self.delegate calendarView:self shouldShowIndicatorForDate:date];
    }
    return NO;
}

- (NSDate *)dateAtIndexPath:(NSIndexPath *)indexPath {
    NSDate* date = [self.startDate dateByAddingDays:indexPath.item];
    return date;
}

//Date Helpers
- (NSIndexPath *)indexPathForDate:(NSDate *)date {
    NSIndexPath *indexPath = nil;
    if (date) {
        NSInteger section = [self.startDate numberOfDaysTillDate:date];
        indexPath = [NSIndexPath indexPathForItem:section inSection:0];
    }
    return indexPath;
}

- (CGRect)frameForHeaderInSection:(NSInteger)section {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:section inSection:0];
    UICollectionViewLayoutAttributes* attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    CGRect firstItemFrame = attributes.frame;
    CGFloat headerHeight = 0.0f;
    return CGRectOffset(firstItemFrame, 0, -headerHeight);
}

  //UICollectionView interaction handlers
- (void)scrollToSectionHeader:(NSInteger)section animated:(BOOL)animated {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:section inSection:0];
    if (indexPath.item < [self offsetIndex]) {
        return;
    }
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:animated];
}

- (void)scrollCalendarToDate:(NSDate *)date fromAgendaView:(BOOL)agendaView animated:(BOOL)animated {
    NSIndexPath *indexPath = [self indexPathForDate:date];
    [self updatesToCellOnIndexPathSelection:indexPath];
    self.selectedDate = date;
    NSSet *visibleIndexPaths = [NSSet setWithArray:[self.collectionView indexPathsForVisibleItems]];
    if (indexPath && ![visibleIndexPaths containsObject:indexPath]) {
        [self scrollToSectionHeader:indexPath.item animated:animated];
    }
    if (agendaView) {
        [self.delegate calendarView:self scrolledToSectionOfDifferentNumberOfRows:3];
    }
}

- (void)agendaViewScrolledFast {
    self.overlayView.alpha = kASOverlayViewOpacity;
}

- (void)agendaViewStoppedScrolling {
    [self hideOverlayView:YES];
}

/**
 Call cell slection logic for the selected indexPath
 */
- (void)updatesToCellOnIndexPathSelection:(NSIndexPath *)indexPath {
    NSIndexPath *pastSelectedIndexPath = [self indexPathForDate:self.selectedDate];
    if ([pastSelectedIndexPath isEqual:indexPath]) {
        return;
    }
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    cell.selected = YES;
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}

/**
 First day of the start date might not be monday, this method returns the offset for the first day for
 the start date.
 */
- (NSInteger)offsetIndex {
    return [[self.startDate firstDayOfMonth] day] + 1;
}

- (void)updateOverlayLabelForIndex:(NSInteger)overlayLabelIndex firstDate:(NSDate *)firstDate endDate:(NSDate *)endDate {
    NSString* text = [firstDate monthYearString];
    // Don't do anything if dates for overlaying labels are out of bounds.
    if (self.startDate > firstDate || endDate > self.endDate) {
        return;
    }
    UICollectionViewLayoutAttributes* firstAttrs = [self.collectionView layoutAttributesForItemAtIndexPath:[self indexPathForDate:firstDate]];
    UICollectionViewLayoutAttributes* lastAttrs = [self.collectionView layoutAttributesForItemAtIndexPath:[self indexPathForDate:endDate]];
    CGRect first = CGRectMake(0, firstAttrs.frame.origin.y, self.collectionView.bounds.size.width, CGRectGetMaxY(lastAttrs.frame) - firstAttrs.frame.origin.y);
    self.overlayLabels[overlayLabelIndex].frame = first;
    self.overlayLabels[overlayLabelIndex].text = text;
}

- (NSArray<UILabel *> *)overlayLabels {
    if (!_overlayLabels) {
        NSMutableArray *labels = [NSMutableArray new];
        for (NSInteger i = 0; i < 3; i ++) {
            UILabel* label = [UILabel new];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = @"4";
            label.userInteractionEnabled = NO;
            //label.backgroundColor = [[UIColor b] colorWithAlphaComponent:0.2f];
            [self.overlayView addSubview:label];
            [labels addObject:label];
        }
        _overlayLabels = labels;
    }
    return _overlayLabels;
}

// Collection view Left and Right margin.
- (CGFloat)marginForCollectionView {
    NSInteger bounds = self.bounds.size.width / DAYS_IN_WEEK;
    CGFloat margin = self.bounds.size.width - bounds * DAYS_IN_WEEK;
    return margin / 2.0f;
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentSize"])
    {
        self.overlayView.frame = CGRectMake(0, 0, self.collectionView.frame.size.width, self.collectionView.contentSize.height);
    }
    
}

@end
