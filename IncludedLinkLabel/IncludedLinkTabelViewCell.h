//
//  IncludedLinkTabelViewCell.h
//  IncludedLinkLabel
//
//  Created by Jung Giuk on 2013/02/10.
//  Copyright (c) 2013年 Jung Giuk. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IncludedLinkLabel;

@interface IncludedLinkTabelViewCell : UITableViewCell
@property (nonatomic, copy) NSString *descriptionText;
@property (nonatomic, strong) IncludedLinkLabel *descriptionLabel;

+ (CGFloat)heightForCellWithText:(NSString *)text;

@end
