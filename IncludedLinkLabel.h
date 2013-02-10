//
//  IncludedLinkLabel.h
//  IncludedLinkLabel
//
//  Created by Jung Giuk on 2013/02/10.
//  Copyright (c) 2013年 Jung Giuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@protocol IncludedLinkLabelDelegate;

@protocol IncludedLinkLabel <NSObject>
@property (nonatomic, copy) id text;
@end

@interface IncludedLinkLabel : UILabel <IncludedLinkLabel, UIGestureRecognizerDelegate>
@property (nonatomic, unsafe_unretained) id <IncludedLinkLabelDelegate> delegate;
@property (readonly, nonatomic, strong) NSArray *links;
@property (nonatomic, strong) NSDictionary *linkAttributes;
@property (nonatomic, strong) NSDictionary *activeLinkAttributes;

- (void)setText:(id)text;
- (void)setText:(id)text
afterInheritingLabelAttributesAndConfiguringWithBlock:(NSMutableAttributedString *(^)(NSMutableAttributedString *mutableAttributedString))block;

@property (readwrite, nonatomic, copy) NSAttributedString *attributedText;

- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result;
- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result
                           attributes:(NSDictionary *)attributes;
- (void)addLinkToURL:(NSURL *)url
           withRange:(NSRange)range;
@end

@protocol IncludedLinkLabelDelegate <NSObject>

@optional
- (void)attributedLabel:(IncludedLinkLabel *)label
   didSelectLinkWithURL:(NSURL *)url;
@end