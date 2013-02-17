//
//  IncludedLinkLabel.m
//  IncludedLinkLabel
//
//  Created by Jung Giuk on 2013/02/10.
//  Copyright (c) 2013年 Jung Giuk. All rights reserved.
//

#import "IncludedLinkLabel.h"
#import "IncludedLinkLabelManager.h"

@interface IncludedLinkLabel ()
@property (nonatomic, copy) NSAttributedString *attributedText;
@property (nonatomic, copy) NSAttributedString *inactiveAttributedText;
@property (nonatomic, copy) NSAttributedString *renderedAttributedText;
@property (nonatomic, assign) CTFramesetterRef framesetter;
@property (nonatomic, assign) CTFramesetterRef highlightFramesetter;
@property (nonatomic, strong) NSArray *links;
@property (nonatomic, strong) NSTextCheckingResult *activeLink;

- (void)commonInit;
- (void)setNeedsFramesetter;
- (void)addLinksWithTextCheckingResults:(NSArray *)results
                             attributes:(NSDictionary *)attributes;
- (NSTextCheckingResult *)linkAtCharacterIndex:(CFIndex)idx;
- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p;
- (CFIndex)characterIndexAtPoint:(CGPoint)p;
- (void)drawFramesetter:(CTFramesetterRef)framesetter
       attributedString:(NSAttributedString *)attributedString
              textRange:(CFRange)textRange
                 inRect:(CGRect)rect
                context:(CGContextRef)c;
@end

@implementation IncludedLinkLabel {
@private
    BOOL _needsFramesetter;
}


@synthesize attributedText = _attributedText;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    [self commonInit];

    return self;
}

- (void)commonInit
{
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = NO;

    self.links = [NSArray array];

    NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
    UIColor *linkColor = [UIColor colorWithRed:102.0/255 green:175.0/255 blue:204.0/255 alpha:1.0];
    [mutableLinkAttributes setObject:(id)[linkColor CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
    self.linkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];

    NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
    UIColor *activeColor = [UIColor colorWithRed:235.0/255 green:127.0/255 blue:94.0/255 alpha:1.0];
    [mutableActiveLinkAttributes setObject:(id)[activeColor CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
    self.activeLinkAttributes = [NSDictionary dictionaryWithDictionary:mutableActiveLinkAttributes];
}

- (void)dealloc
{
    if (_framesetter) CFRelease(_framesetter);
    if (_highlightFramesetter) CFRelease(_highlightFramesetter);
}

#pragma mark -

- (void)setAttributedText:(NSAttributedString *)text
{
    if ([text isEqualToAttributedString:_attributedText]) {
        return;
    }
    _attributedText = [text copy];
    [self setNeedsFramesetter];
}

- (void)setNeedsFramesetter
{
    self.renderedAttributedText = nil;
    _needsFramesetter = YES;
}

- (CTFramesetterRef)framesetter
{
    if (_needsFramesetter) {
        @synchronized(self) {
            if (_framesetter) CFRelease(_framesetter);
            if (_highlightFramesetter) CFRelease(_highlightFramesetter);

            self.framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.renderedAttributedText);
            self.highlightFramesetter = nil;
            _needsFramesetter = NO;
        }
    }
    return _framesetter;
}

- (NSAttributedString *)renderedAttributedText
{
    if (!_renderedAttributedText) {
        self.renderedAttributedText = [IncludedLinkLabelManager nsAttributedStringBySettingColorFromContext:self.attributedText color:self.textColor];
    }
    return _renderedAttributedText;
}

#pragma mark -

- (void)addLinksWithTextCheckingResults:(NSArray *)results attributes:(NSDictionary *)attributes
{
    self.links = [self.links arrayByAddingObjectsFromArray:results];

    if (attributes) {
        NSMutableAttributedString *mutableAttributedString = [self.attributedText mutableCopy];
        for (NSTextCheckingResult *result in results) {
            [mutableAttributedString addAttributes:attributes range:result.range];
        }
        self.attributedText = mutableAttributedString;
        [self setNeedsDisplay];
    }
}

- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result attributes:(NSDictionary *)attributes
{
    [self addLinksWithTextCheckingResults:[NSArray arrayWithObject:result] attributes:attributes];
}

- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result
{
    [self addLinkWithTextCheckingResult:result attributes:self.linkAttributes];
}

- (void)addLinkToURL:(NSURL *)url withRange:(NSRange)range
{
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult linkCheckingResultWithRange:range URL:url]];
}

#pragma mark -

- (NSTextCheckingResult *)linkAtCharacterIndex:(CFIndex)idx
{
    for (NSTextCheckingResult *result in self.links) {
        if (NSLocationInRange((NSUInteger)idx, result.range)) {
            return result;
        }
    }
    return nil;
}

- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p
{
    CFIndex idx = [self characterIndexAtPoint:p];
    return [self linkAtCharacterIndex:idx];
}

- (CFIndex)characterIndexAtPoint:(CGPoint)p
{
    if (!CGRectContainsPoint(self.bounds, p)) {
        return NSNotFound;
    }

    CGRect textRect = [self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines];
    if (!CGRectContainsPoint(textRect, p)) {
        return NSNotFound;
    }

    // Offset tap coordinates by textRect
    p = CGPointMake(p.x - textRect.origin.x, p.y - textRect.origin.y);
    p = CGPointMake(p.x, textRect.size.height - p.y);

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, textRect);
    CTFrameRef frame = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, [self.attributedText length]), path, NULL);
    if (frame == NULL) {
        CFRelease(path);
        return NSNotFound;
    }

    CFArrayRef lines = CTFrameGetLines(frame);
    NSInteger numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    if (numberOfLines == 0) {
        CFRelease(frame);
        CFRelease(path);
        return NSNotFound;
    }

    NSUInteger idx = NSNotFound;

    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);

    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);

        // lineのbounding情報を取得
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat yMin = floor(lineOrigin.y - descent);
        CGFloat yMax = ceil(lineOrigin.y + ascent);

        // 既にラインを過ぎちゃったかを確認
        if (p.y > yMax) {
            break;
        }
        // ポイントがこのラインの内にあるかを確認（vertically）
        if (p.y >= yMin) {
            // ポイントがこのラインの内にあるかを確認（horizontally）
            if (p.x >= lineOrigin.x && p.x <= lineOrigin.x + width) {
                // Convert coordinates（CT coordinates → line-relative coordinates）
                CGPoint relativePoint = CGPointMake(p.x - lineOrigin.x, p.y - lineOrigin.y);
                idx = CTLineGetStringIndexForPosition(line, relativePoint);
                break;
            }
        }
    }
    CFRelease(frame);
    CFRelease(path);

    return idx;
}

- (void)drawFramesetter:(CTFramesetterRef)framesetter
       attributedString:(NSAttributedString *)attributedString
              textRange:(CFRange)textRange
                 inRect:(CGRect)rect
                context:(CGContextRef)c
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, textRange, path, NULL);
    CFArrayRef lines = CTFrameGetLines(frame);
    NSInteger numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    BOOL truncateLastLine = (self.lineBreakMode == UILineBreakModeHeadTruncation || self.lineBreakMode == UILineBreakModeMiddleTruncation || self.lineBreakMode == UILineBreakModeTailTruncation);

    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);

    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y);
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);

        if (lineIndex == numberOfLines - 1 && truncateLastLine) {
            // Check if the range of text in the last line reaches the end of the full attributed string
            CFRange lastLineRange = CTLineGetStringRange(line);

            if (!(lastLineRange.length == 0 && lastLineRange.location == 0) && lastLineRange.location + lastLineRange.length < textRange.location + textRange.length) {
                // Get correct truncationType and attribute position
                CTLineTruncationType truncationType;
                NSUInteger truncationAttributePosition = lastLineRange.location;
                UILineBreakMode lineBreakMode = self.lineBreakMode;

                // Multiple lines, only use UILineBreakModeTailTruncation
                if (numberOfLines != 1) {
                    lineBreakMode = UILineBreakModeTailTruncation;
                }

                switch (lineBreakMode) {
                    case UILineBreakModeHeadTruncation:
                        truncationType = kCTLineTruncationStart;
                        break;
                    case UILineBreakModeMiddleTruncation:
                        truncationType = kCTLineTruncationMiddle;
                        truncationAttributePosition += (lastLineRange.length / 2);
                        break;
                    case UILineBreakModeTailTruncation:
                    default:
                        truncationType = kCTLineTruncationEnd;
                        truncationAttributePosition += (lastLineRange.length - 1);
                        break;
                }

                // Get the attributes and use them to create the truncation token string
                NSDictionary *tokenAttributes = [attributedString attributesAtIndex:truncationAttributePosition effectiveRange:NULL];
                NSString *truncationTokenString = @"\u2026"; // Unicode Character
                NSAttributedString *attributedTokenString = [[NSAttributedString alloc] initWithString:truncationTokenString attributes:tokenAttributes];
                CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedTokenString);

                NSMutableAttributedString *truncationString = [[attributedString attributedSubstringFromRange:NSMakeRange(lastLineRange.location, lastLineRange.length)] mutableCopy];
                if (lastLineRange.length > 0) {
                    unichar lastCharacter = [[truncationString string] characterAtIndex:lastLineRange.length - 1];
                    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter]) {
                        [truncationString deleteCharactersInRange:NSMakeRange(lastLineRange.length - 1, 1)];
                    }
                }
                [truncationString appendAttributedString:attributedTokenString];
                CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);

                // Truncate the line in case it is too long.
                CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, rect.size.width, truncationType, truncationToken);
                if (!truncatedLine) {
                    truncatedLine = CFRetain(truncationToken);
                }

                // Adjust pen offset for flush depending
                CGFloat flushFactor = 0.0f;
                CGFloat penOffset = CTLineGetPenOffsetForFlush(truncatedLine, flushFactor, rect.size.width);
                CGContextSetTextPosition(c, penOffset, lineOrigin.y);
                CTLineDraw(truncatedLine, c);

                CFRelease(truncatedLine);
                CFRelease(truncationLine);
                CFRelease(truncationToken);
            } else {
                CTLineDraw(line, c);
            }
        } else {
            CTLineDraw(line, c);
        }
    }
    CFRelease(frame);
    CFRelease(path);
}

#pragma mark - IncludedLinkLabel

- (void)setText:(id)text
{
    if ([text isKindOfClass:[NSString class]]) {
        [self setText:text attributesWithBlock:nil];
        return;
    }
    self.attributedText = text;
    self.activeLink = nil;
    self.links = [NSArray array];
    
    [super setText:[self.attributedText string]];

    NSRegularExpression *regexp = [IncludedLinkLabelManager urlRegularExpression];
    NSRange linkRange = [regexp rangeOfFirstMatchInString:self.text options:0 range:NSMakeRange(0, [self.text length])];
    if (linkRange.length > 0) {
        NSURL *url = [NSURL URLWithString:[self.text substringWithRange:linkRange]];
        [self addLinkToURL:url withRange:linkRange];
    }

}

- (void)setText:(id)text attributesWithBlock:(NSMutableAttributedString *(^)(NSMutableAttributedString *mutableAttributedString))block
{
    NSMutableAttributedString *mutableAttributedString = nil;
    if ([text isKindOfClass:[NSString class]]) {
    mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:[IncludedLinkLabelManager nsAttributedStringAttributesFromLabel:self]];
    }
    if (block) {
        mutableAttributedString = block(mutableAttributedString);
    }
    [self setText:mutableAttributedString];
}

- (void)setActiveLink:(NSTextCheckingResult *)activeLink
{
    _activeLink = activeLink;

    if (_activeLink && [self.activeLinkAttributes count] > 0) {
        if (!_inactiveAttributedText) {
            _inactiveAttributedText = [self.attributedText copy];
        }

        NSMutableAttributedString *mutableAttributedString = [_inactiveAttributedText mutableCopy];
        [mutableAttributedString addAttributes:self.activeLinkAttributes range:_activeLink.range];
        self.attributedText = mutableAttributedString;
    } else if (_inactiveAttributedText) {
        self.attributedText = _inactiveAttributedText;
        _inactiveAttributedText = nil;
	    }
    [self setNeedsDisplay];
}

#pragma mark - UILabel

- (CGRect)textRectForBounds:(CGRect)bounds
     limitedToNumberOfLines:(NSInteger)numberOfLines
{
    if (!self.attributedText) {
        return [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    }

    CGRect textRect = bounds;
    textRect.size.height = fmaxf(self.font.pointSize * 2.0f, bounds.size.height);

    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, CFRangeMake(0, [self.attributedText length]), NULL, textRect.size, NULL);
    textSize = CGSizeMake(ceilf(textSize.width), ceilf(textSize.height));

    return textRect;
}

- (void)drawTextInRect:(CGRect)rect
{
    if (!self.attributedText) {
        [super drawTextInRect:rect];
        return;
    }

    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(c, CGAffineTransformIdentity);
    CGContextTranslateCTM(c, 0.0f, rect.size.height);
    CGContextScaleCTM(c, 1.0f, -1.0f);
    CFRange textRange = CFRangeMake(0, [self.attributedText length]);

    // First, get the text rect
    CGRect textRect = [self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines];
    CGContextTranslateCTM(c, 0.0f, rect.size.height - textRect.origin.y - textRect.size.height);

    [self drawFramesetter:self.framesetter attributedString:self.renderedAttributedText textRange:textRange inRect:textRect context:c];
}


#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];

    self.activeLink = [self linkAtPoint:[touch locationInView:self]];

    if (!self.activeLink) {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        UITouch *touch = [touches anyObject];

        if (self.activeLink != [self linkAtPoint:[touch locationInView:self]]) {
            self.activeLink = nil;
        }
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        NSTextCheckingResult *result = self.activeLink;
        self.activeLink = nil;

        if(result.resultType == NSTextCheckingTypeLink) {
            if ([self.delegate respondsToSelector:@selector(includedLinkLabel:didSelectLinkWithURL:)]) {
                [self.delegate includedLinkLabel:self didSelectLinkWithURL:result.URL];
                return;
            }
        }
    }
    else {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        self.activeLink = nil;
    } else {
        [super touchesCancelled:touches withEvent:event];
    }
}


@end