//
//  IncludedLinkLabelManager.m
//  IncludedLinkLabel
//
//  Created by Jung Giuk on 2013/02/13.
//  Copyright (c) 2013年 Jung Giuk. All rights reserved.
//

#import "IncludedLinkLabelManager.h"

static CGFloat const kLineHeight = 14.0f;
static CGFloat const kLineSpacing = 4.0f;
static NSString *const kUrlRegularPattern = @"\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))";

@implementation IncludedLinkLabelManager

+ (NSRegularExpression *)urlRegularExpression
{
    NSRegularExpression *urlRegularExpression = [[NSRegularExpression alloc] initWithPattern:kUrlRegularPattern options:NSRegularExpressionCaseInsensitive error:NULL];
    return urlRegularExpression;
}

+ (NSDictionary *)nsAttributedStringAttributesFromLabel:(UILabel *)label
{
    NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionary];

    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)label.font.fontName, label.font.pointSize, NULL);
    [mutableAttributes setObject:(__bridge id)font forKey:(NSString *)kCTFontAttributeName];
    CFRelease(font);

    [mutableAttributes setObject:(id)[label.textColor CGColor] forKey:(NSString *)kCTForegroundColorAttributeName];

    CTLineBreakMode lineBreakMode = kCTLineBreakByCharWrapping;
    CGFloat minLineHeight = kLineHeight;
    CGFloat maxLineHeight = minLineHeight;
    CGFloat minLineSpacing = kLineSpacing;
    CGFloat maxLineSpacing = minLineSpacing;

    CTParagraphStyleSetting paragraphStyles[5] = {
		{.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void *)&lineBreakMode},
        {.spec = kCTParagraphStyleSpecifierMinimumLineHeight,   .valueSize = sizeof(CGFloat),   .value = &minLineHeight},
        {.spec = kCTParagraphStyleSpecifierMaximumLineHeight,   .valueSize = sizeof(CGFloat),   .value = &maxLineHeight},
        {.spec = kCTParagraphStyleSpecifierMinimumLineSpacing,  .valueSize = sizeof(CGFloat),   .value = &minLineSpacing},
        {.spec = kCTParagraphStyleSpecifierMaximumLineSpacing,  .valueSize = sizeof(CGFloat),   .value = &maxLineSpacing},
	};
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyles, 5);
	[mutableAttributes setObject:(__bridge id)paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
	CFRelease(paragraphStyle);

    return [NSDictionary dictionaryWithDictionary:mutableAttributes];
}

+ (NSAttributedString *)nsAttributedStringBySettingColorFromContext:(NSAttributedString *)attributedString color:(UIColor *)color
{
    if (!color)
        return attributedString;

    CGColorRef colorRef = color.CGColor;
    NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
    [mutableAttributedString enumerateAttribute:(NSString *)kCTForegroundColorFromContextAttributeName inRange:NSMakeRange(0, [mutableAttributedString length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        CFBooleanRef usesColorFromContext = (__bridge CFBooleanRef)value;
        if (usesColorFromContext && CFBooleanGetValue(usesColorFromContext)) {
            CFRange updateRange = CFRangeMake(range.location, range.length);
            CFAttributedStringSetAttribute((__bridge CFMutableAttributedStringRef)mutableAttributedString, updateRange, kCTForegroundColorAttributeName, colorRef);
            CFAttributedStringRemoveAttribute((__bridge CFMutableAttributedStringRef)mutableAttributedString, updateRange, kCTForegroundColorFromContextAttributeName);
        }
    }];

    return mutableAttributedString;
}

@end
