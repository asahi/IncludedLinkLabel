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

@interface IncludedLinkLabel : UILabel <UIGestureRecognizerDelegate>
@property (nonatomic, unsafe_unretained) id <IncludedLinkLabelDelegate> delegate;
@property (nonatomic, assign) BOOL isTouched;

- (void)setText:(id)text;
- (void)setText:(id)text attributesWithBlock:(NSMutableAttributedString *(^)(NSMutableAttributedString *mutableAttributedString))block;
- (void)addLinkToURL:(NSURL *)url withRange:(NSRange)range;
@end


@protocol IncludedLinkLabelDelegate <NSObject>
@optional
- (void)includedLinkLabel:(IncludedLinkLabel *)label didSelectLinkWithURL:(NSURL *)url;
@end