//
//  ASCalendarCellViewModel.m
//  AshishCalendarApp
//
//  Created by Ashish Singh on 2/3/18.
//  Copyright © 2018 Ashish. All rights reserved.
//

#import "ASCalendarCellViewModel.h"
#import "NSDate+AS_DateHelpers.h"
#import "UIColor+AS.h"
@interface ASCalendarCellViewModel()

@end
@implementation ASCalendarCellViewModel
- (instancetype)initWithCalendarDateSource:(id<ASCalendarDateOperationDataSource>)calendarDataSource indexPath:(NSIndexPath *)indexPath{
    self = [super init];
    if (self) {
        _indicatorViewHidden = YES;
        if (indexPath.item < [calendarDataSource offsetIndex]) {
            return self;
        }
        NSDate *itemDate = [calendarDataSource dateAtIndexPath:indexPath];
        NSDate *currentDate = [NSDate date];
        NSInteger currentYear = [currentDate year];
        NSInteger itemYear = [itemDate year];
        /**
         Month or year strings will be set only when item date is first day of the month.
         Set year string only when the item date and today date have different years.
         */
        if ([[itemDate firstDayOfMonth] isEqual:itemDate]) {
            if (currentYear != itemYear) {
                _year = [NSString stringWithFormat:@"%ld", itemYear];
            }
            NSInteger monthIndex = [itemDate month];
            _month = [NSDate shortMonthNames][monthIndex];
        }
        NSDate *today = [NSDate date];
        BOOL showIndicator = NO;
        _textColor = [UIColor grayColor];
        if ([itemDate isEqualToDate:today]) {
            _textColor = [UIColor redColor];
        }
        _userInteraction = YES;
        NSInteger day = [itemDate day];
        _dayText = [NSString stringWithFormat:@"%d", (int)day];
        if ([itemDate isEqualToDate:calendarDataSource.selectedDate]) {
            _selectedItem = YES;
        }
        showIndicator = [calendarDataSource shouldShowIndicatorForDate:itemDate];
        _indicatorViewHidden = !showIndicator;
        _backgroundColor = [itemDate month] % 2 == 0 ? [UIColor whiteColor] : [UIColor as_lightGrayColor];
    }
    return self;
}
@end


