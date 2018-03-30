//
//  ASCalendarDayCollectionViewCell.m
//  AshishCalendarApp
//
//  Created by Ashish Singh on 1/27/18.
//  Copyright © 2018 Ashish. All rights reserved.
//

#import "ASCalendarDayCollectionViewCell.h"
#import "UIColor+AS.h"

static CGFloat const kASMonthYearFontSize = 15.f;
static CGFloat const kASDayLabelFontSize = 19.f;

@interface ASCalendarDayCollectionViewCell()
@property (nonatomic, strong) UILabel *dayLabel;
@property (nonatomic, strong) UIView *bottomSeprator;
@property (nonatomic, strong) UIView *highlightView;
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UILabel *yearLabel;
@property (nonatomic, strong) ASCalendarCellViewModel *viewModel;
@end
@implementation ASCalendarDayCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.highlightView = [UIView new];
    self.highlightView.hidden = YES;
    self.highlightView.backgroundColor = [UIColor blueColor];
    self.indicatorView = [UIView new];
    self.indicatorView.backgroundColor = [UIColor as_mediumLightGrayColor];
    self.indicatorView.hidden = YES;
    [self.contentView addSubview:self.indicatorView];
    [self.contentView addSubview:self.highlightView];
    [self.contentView addSubview:self.dayLabel];
    [self.contentView addSubview:self.monthLabel];
    [self.contentView addSubview:self.yearLabel];
    self.contentView.backgroundColor = [UIColor as_lightGrayColor];
    self.dayLabel.backgroundColor = [UIColor clearColor];
    //self.dayLabel.backgroundColor = [UIColor clearColor];
    self.bottomSeprator = [UIView new];
    self.bottomSeprator.backgroundColor = [UIColor as_mediumLightGrayColor];
    [self.contentView addSubview:self.bottomSeprator];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.contentView.bounds.size;
    self.bottomSeprator.frame = CGRectMake(0, 0, CGRectGetMaxX(self.bounds), 1);
    CGFloat indicatorWidth = 5.0f;
    CGFloat bottomMarginForIndicatorView = 6.f;
    CGRect indicatorFrame = CGRectMake((size.width - indicatorWidth)/2.0f, 0, indicatorWidth, indicatorWidth);
    indicatorFrame.origin.y = CGRectGetMaxY(self.contentView.bounds) - bottomMarginForIndicatorView - indicatorWidth;
    self.indicatorView.frame = indicatorFrame;
    self.indicatorView.layer.cornerRadius = indicatorFrame.size.height / 2.0f;
    self.highlightView.frame = CGRectInset(self.bounds, 4, 4);
    self.highlightView.layer.cornerRadius = self.highlightView.frame.size.height / 2.0f;
    // Layout labels based on year label and month label visibility.
    if (self.yearLabel.hidden && self.monthLabel.hidden) {
        self.dayLabel.frame = self.bounds;
    }
    else {
        CGFloat margin = [self labelMargin];
        self.monthLabel.frame = CGRectMake(0, margin + 1, self.bounds.size.width, [self.monthLabel sizeThatFits:CGSizeZero].height);
        self.dayLabel.frame = CGRectMake(0, CGRectGetMaxY(self.monthLabel.frame) + margin, self.bounds.size.width, [self.dayLabel sizeThatFits:CGSizeZero].height);
        self.yearLabel.frame = CGRectMake(0, CGRectGetMaxY(self.dayLabel.frame) + margin, self.bounds.size.width, [self.yearLabel sizeThatFits:CGSizeZero].height);
    }
}

- (void)configureCellWith:(ASCalendarCellViewModel *)viewModel {
    self.viewModel = viewModel;
    self.userInteractionEnabled = viewModel.userInteraction;
    self.dayLabel.text = viewModel.dayText;
    self.indicatorView.hidden = viewModel.indicatorViewHidden;
    self.selected = viewModel.selectedItem;
    self.textColor = viewModel.textColor;
    self.contentView.backgroundColor = viewModel.backgroundColor;
    self.yearLabel.hidden = viewModel.year == nil;
    self.monthLabel.hidden = viewModel.month == nil;
    self.yearLabel.text = viewModel.year;
    self.monthLabel.text = viewModel.month;
    self.indicatorView.hidden = viewModel.indicatorViewHidden || viewModel.month != nil;
    self.dayLabel.font = [UIFont systemFontOfSize:[self dayLabelFontSize]];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setDayText:(NSString *)text{
    self.dayLabel.text = text;
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    self.dayLabel.textColor = textColor;
    if ([textColor isEqual:[UIColor redColor]]) {
        self.highlightView.backgroundColor = textColor;
    }
    else {
        self.highlightView.backgroundColor = [UIColor blueColor];
    }
}

- (UILabel *)dayLabel {
    if (!_dayLabel) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.textAlignment = NSTextAlignmentCenter;
        label.adjustsFontSizeToFitWidth = YES;
        label.text = @"";
        label.font = [UIFont systemFontOfSize:14.0f];
        label.textColor = [UIColor blackColor];
        self.dayLabel = label;
    }
    return _dayLabel;
}

- (UILabel *)monthLabel {
    if (!_monthLabel) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.textAlignment = NSTextAlignmentCenter;
        label.adjustsFontSizeToFitWidth = YES;
        label.text = @"Jan";
        label.font = [UIFont systemFontOfSize:10.0f];
        label.textColor = [UIColor grayColor];
        self.monthLabel = label;
    }
    return _monthLabel;
}

- (UILabel *)yearLabel {
    if (!_yearLabel) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"2017";
        label.adjustsFontSizeToFitWidth = YES;
        label.font = [UIFont systemFontOfSize:10.0f];
        label.textColor = [UIColor grayColor];
        self.yearLabel = label;
    }
    return _yearLabel;
}

/**
 Margin between labels and between label and contentView based on date.
 Scenarios could be only dayLabel is visible, dayLabel and Month Label visible, or
 all of the labels are visible. Marging is calculated based on the current scenario.
 */
- (CGFloat)labelMargin {
    CGFloat height = [self.dayLabel sizeThatFits:CGSizeZero].height + [self.monthLabel sizeThatFits:CGSizeZero].height;
    if (!self.viewModel.year) {
        height = (self.bounds.size.height - height) / 3.0f;
        return floorf(height);
    }
    height = height + [self.yearLabel sizeThatFits:CGSizeZero].height;
    height = (self.bounds.size.height - height) / 4.0f;
    return floorf(height);
}

- (void)setSelected:(BOOL)selected {
    self.highlightView.hidden = !selected;
    self.dayLabel.textColor = selected ? [UIColor whiteColor] : self.textColor;
    // Update visibility of month and year labels only when view model has month string.
    if (self.viewModel.month) {
        self.monthLabel.hidden = self.viewModel.month == nil || selected;
        self.yearLabel.hidden = self.viewModel.year == nil || selected;
        self.dayLabel.font = [UIFont systemFontOfSize:[self dayLabelFontSize]];
        // Force Cell layout again.
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

/**
 Font size changes based on year label and month label visibility.
 */
- (CGFloat)dayLabelFontSize {
    CGFloat fontSize = self.viewModel.year ? kASMonthYearFontSize : self.viewModel.month ? 16.0f : kASDayLabelFontSize;
    return self.selected ? kASDayLabelFontSize : fontSize;
}

@end
