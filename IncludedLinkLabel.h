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
@property (readwrite, nonatomic, copy) NSAttributedString *attributedText;
@property (nonatomic, strong) NSDictionary *linkAttributes;
@property (nonatomic, strong) NSDictionary *activeLinkAttributes;
@property (nonatomic, assign) UIDataDetectorTypes dataDetectorTypes;
@property (nonatomic, assign) CGFloat lineHeightMultiple;
@property (nonatomic, assign) CGFloat leading;
@property (nonatomic, assign) UIEdgeInsets textInsets;
@property (nonatomic, assign) CGFloat firstLineIndent;
@property (nonatomic, strong) NSString *truncationTokenString;

- (void)setText:(id)text;
- (void)setText:(id)text
afterInheritingLabelAttributesAndConfiguringWithBlock:(NSMutableAttributedString *(^)(NSMutableAttributedString *mutableAttributedString))block;
- (void)addLinkToURL:(NSURL *)url withRange:(NSRange)range;

@end


@protocol IncludedLinkLabelDelegate <NSObject>
@optional
- (void)includedLinkLabel:(IncludedLinkLabel *)label didSelectLinkWithURL:(NSURL *)url;
@end