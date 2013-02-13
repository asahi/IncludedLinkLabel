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

static CGFloat const kEspressoDescriptionTextFontSize = 15;
static CGFloat const kAttributedTableViewCellVerticalMargin = 10.0f;

static NSRegularExpression *_urlRegularExpression;
static inline NSRegularExpression * URLRegularExpression() {
    if (!_urlRegularExpression) {
        _urlRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"http?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\.]*(\\?\\S+)?)?)?" options:NSRegularExpressionCaseInsensitive error:NULL];
    }
    return _urlRegularExpression;
}

@implementation IncludedLinkTabelViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [[UIScreen mainScreen] scale];

        _descriptionLabel = [[IncludedLinkLabel alloc] initWithFrame:CGRectZero];
        _descriptionLabel.font = [UIFont systemFontOfSize:kEspressoDescriptionTextFontSize];
        _descriptionLabel.numberOfLines = 0;
        _descriptionLabel.linkAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCTUnderlineStyleAttributeName];

        NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
        [mutableActiveLinkAttributes setValue:(id)[[UIColor cyanColor] CGColor] forKey:(NSString *)kCTForegroundColorAttributeName];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithBool:NO] forKey:(NSString *)kCTUnderlineStyleAttributeName];
        _descriptionLabel.activeLinkAttributes = mutableActiveLinkAttributes;
        [self.contentView addSubview:_descriptionLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setDescriptionText:(NSString *)descriptionText {
    [self willChangeValueForKey:@"descriptionText"];
    _descriptionText = [descriptionText copy];
    [self didChangeValueForKey:@"descriptionText"];

    [_descriptionLabel setText:_descriptionText attributesWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        NSRange stringRange = NSMakeRange(0, [mutableAttributedString length]);

        NSRegularExpression *regexp = URLRegularExpression();
        NSRange urlRange = [regexp rangeOfFirstMatchInString:[mutableAttributedString string] options:0 range:stringRange];
        UIFont *systemFont = [UIFont systemFontOfSize:kEspressoDescriptionTextFontSize];
        CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)systemFont.fontName, systemFont.pointSize, NULL);
        if (font) {
            [mutableAttributedString removeAttribute:(NSString *)kCTFontAttributeName range:urlRange];
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:urlRange];
            CFRelease(font);
        }
        return mutableAttributedString;
    }];

    NSRegularExpression *regexp = URLRegularExpression();
    NSRange linkRange = [regexp rangeOfFirstMatchInString:_descriptionText options:0 range:NSMakeRange(0, [_descriptionText length])];
    if (linkRange.length > 0) {
        NSURL *url = [NSURL URLWithString:[_descriptionText substringWithRange:linkRange]];
        [_descriptionLabel addLinkToURL:url withRange:linkRange];
    }
}

+ (CGFloat)heightForCellWithText:(NSString *)text {
    CGFloat height = 10.0f;
    // ceilf関数 : x 以上の最小の整数値を計算し，結果を float型で返し
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
