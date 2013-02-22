//
//  IncludedLinkTabelViewCell.m
//  IncludedLinkLabel
//
//  Created by Jung Giuk on 2013/02/10.
//  Copyright (c) 2013年 Jung Giuk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "IncludedLinkTabelViewCell.h"
#import "IncludedLinkLabel.h"

static CGFloat const kEspressoDescriptionTextFontSize = 14;
static CGFloat const kAttributedTableViewCellVerticalMargin = 10.0f;

@implementation IncludedLinkTabelViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.descriptionLabel = [[IncludedLinkLabel alloc] initWithFrame:CGRectZero];
        self.descriptionLabel.font = [UIFont systemFontOfSize:kEspressoDescriptionTextFontSize];
        self.descriptionLabel.numberOfLines = 0;
        self.descriptionLabel.lineBreakMode = UILineBreakModeWordWrap;

        [self.contentView addSubview:self.descriptionLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)setDescriptionText:(NSString *)descriptionText {
    [self.descriptionLabel setText:descriptionText];
}

+ (CGFloat)heightForCellWithText:(NSString *)text {
    CGFloat height = 10.0f;
    height += ceilf([text sizeWithFont:[UIFont systemFontOfSize:kEspressoDescriptionTextFontSize] constrainedToSize:CGSizeMake(270.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    height += kAttributedTableViewCellVerticalMargin;
    return height;
}

#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.hidden = YES;
    self.detailTextLabel.hidden = YES;

    _descriptionLabel.frame = CGRectOffset(CGRectInset(self.bounds, 20.0f, 5.0f), -10.0f, 0.0f);
}


@end
