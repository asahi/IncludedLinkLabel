//
//  IncludedLinkLabelManager.m
//  IncludedLinkLabel
//
//  Created by Jung Giuk on 2013/02/13.
//  Copyright (c) 2013年 Jung Giuk. All rights reserved.
//

#import "IncludedLinkLabelManager.h"


@implementation IncludedLinkLabelManager

+ (NSRegularExpression *)urlRegularExpression
{
    NSString *urlRegularPattern = @"http?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\.]*(\\?\\S+)?)?)?";
    NSRegularExpression *urlRegularExpression = [[NSRegularExpression alloc] initWithPattern:urlRegularPattern options:NSRegularExpressionCaseInsensitive error:NULL];
    return urlRegularExpression;
}

+ (NSDictionary *)nsAttributedStringAttributesFromLabel:(UILabel *)label
{
    NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionary];

    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)label.font.fontName, label.font.pointSize, NULL);
    [mutableAttributes setObject:(__bridge id)font forKey:(NSString *)kCTFontAttributeName];
    CFRelease(font);

    [mutableAttributes setObject:(id)[label.textColor CGColor] forKey:(NSString *)kCTForegroundColorAttributeName];

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
