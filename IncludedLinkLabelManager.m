//
//  IncludedLinkLabelManager.m
//  IncludedLinkLabel
//
//  Created by Jung Giuk on 2013/02/13.
//  Copyright (c) 2013年 Jung Giuk. All rights reserved.
//

#import "IncludedLinkLabelManager.h"
#import "IncludedLinkLabel.h"


@implementation IncludedLinkLabelManager

+ (NSRegularExpression *)urlRegularExpression {
    NSString *urlRegularPattern = @"http?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\.]*(\\?\\S+)?)?)?";
    NSRegularExpression *urlRegularExpression = [[NSRegularExpression alloc] initWithPattern:urlRegularPattern options:NSRegularExpressionCaseInsensitive error:NULL];
    return urlRegularExpression;
}


+ (NSDictionary *)nsAttributedStringAttributesFromLabel:(IncludedLinkLabel *)label
{
    NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionary];

    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)label.font.fontName, label.font.pointSize, NULL);
    [mutableAttributes setObject:(__bridge id)font forKey:(NSString *)kCTFontAttributeName];
    CFRelease(font);

    [mutableAttributes setObject:(id)[label.textColor CGColor] forKey:(NSString *)kCTForegroundColorAttributeName];

    CGFloat lineSpacingAdjustment = ceilf(label.font.lineHeight - label.font.ascender + label.font.descender);
    CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;

    CTParagraphStyleSetting paragraphStyles[2] = {
        {.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void *)&lineBreakMode},
        {.spec = kCTParagraphStyleSpecifierLineSpacingAdjustment, .valueSize = sizeof (CGFloat), .value = (const void *)&lineSpacingAdjustment},
    };

    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyles, 2);
    [mutableAttributes setObject:(__bridge id)paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
    CFRelease(paragraphStyle);
    
    return [NSDictionary dictionaryWithDictionary:mutableAttributes];
}


+ (NSAttributedString *) nsAttributedStringBySettingColorFromContext:(NSAttributedString *)attributedString color:(UIColor *)color
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


+ (NSAttributedString *) nsAttributedStringByScalingFontSize:(NSAttributedString *)attributedString scale:(CGFloat)scale minimumFontSize:(CGFloat)minFontSize {
    NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
    [mutableAttributedString enumerateAttribute:(NSString *)kCTFontAttributeName
                                        inRange:NSMakeRange(0, [mutableAttributedString length])
                                        options:0
                                     usingBlock:^(id value, NSRange range, BOOL *stop) {
                                         CTFontRef font = (__bridge CTFontRef)value;
                                         if (font) {
                                             CGFloat scaledFontSize = floorf(CTFontGetSize(font) * scale);
                                             CTFontRef scaledFont = CTFontCreateCopyWithAttributes(font, fmaxf(scaledFontSize, minFontSize), NULL, NULL);
                                             CFAttributedStringSetAttribute((CFMutableAttributedStringRef)mutableAttributedString, CFRangeMake(range.location, range.length), kCTFontAttributeName, scaledFont);
            CFRelease(scaledFont);
        }
    }];

    return mutableAttributedString;
}

@end
