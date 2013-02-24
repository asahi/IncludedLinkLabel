//
//  IncludedLinkLabelManager.h
//  IncludedLinkLabel
//
//  Created by Jung Giuk on 2013/02/13.
//  Copyright (c) 2013年 Jung Giuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@interface IncludedLinkLabelManager : NSObject
+ (NSRegularExpression *)urlRegularExpression;
+ (NSDictionary *)nsAttributedStringAttributesFromLabel:(UILabel *)label;
+ (NSAttributedString *)nsAttributedStringBySettingColorFromContext:(NSAttributedString *)attributedString color:(UIColor *)color;
@end
