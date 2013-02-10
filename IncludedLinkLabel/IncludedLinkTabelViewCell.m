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

static CGFloat const kEspressoDescriptionTextFontSize = 17;
static CGFloat const kAttributedTableViewCellVerticalMargin = 20.0f;

static NSRegularExpression *__nameRegularExpression;
static inline NSRegularExpression * NameRegularExpression() {
    if (!__nameRegularExpression) {
        __nameRegularExpression = [[NSRegularExpression alloc] initWithPattern://@"^\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
                                   @"http?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\.]*(\\?\\S+)?)?)?" options:NSRegularExpressionCaseInsensitive error:NULL];

    }
    
    return __nameRegularExpression;
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
        _descriptionLabel.textColor = [UIColor darkGrayColor];
        _descriptionLabel.numberOfLines = 0;
        _descriptionLabel.linkAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCTUnderlineStyleAttributeName];

        NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
        [mutableActiveLinkAttributes setValue:(id)[[UIColor redColor] CGColor] forKey:(NSString *)kCTForegroundColorAttributeName];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithBool:NO] forKey:(NSString *)kCTUnderlineStyleAttributeName];
        _descriptionLabel.activeLinkAttributes = mutableActiveLinkAttributes;
        _descriptionLabel.highlightedTextColor = [UIColor whiteColor];
        _descriptionLabel.shadowColor = [UIColor colorWithWhite:0.87 alpha:1.0];
        _descriptionLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
        
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

    [_descriptionLabel setText:_descriptionText afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        NSRange stringRange = NSMakeRange(0, [mutableAttributedString length]);

        NSRegularExpression *regexp = NameRegularExpression();
        NSRange nameRange = [regexp rangeOfFirstMatchInString:[mutableAttributedString string] options:0 range:stringRange];
        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:kEspressoDescriptionTextFontSize];
        CTFontRef boldFont = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
        if (boldFont) {
            [mutableAttributedString removeAttribute:(NSString *)kCTFontAttributeName range:nameRange];
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)boldFont range:nameRange];
            CFRelease(boldFont);
        }
        return mutableAttributedString;
    }];

    NSRegularExpression *regexp = NameRegularExpression();
    NSRange linkRange = [regexp rangeOfFirstMatchInString:_descriptionText options:0 range:NSMakeRange(0, [_descriptionText length])];
    NSURL *url = [NSURL URLWithString:[_descriptionText substringWithRange:linkRange]];
    [_descriptionLabel addLinkToURL:url withRange:linkRange];
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
