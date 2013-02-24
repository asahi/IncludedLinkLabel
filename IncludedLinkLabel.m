//
//  IncludedLinkLabel.m
//  IncludedLinkLabel
//
//  Created by Jung Giuk on 2013/02/10.
//  Copyright (c) 2013年 Jung Giuk. All rights reserved.
//

#import "IncludedLinkLabel.h"
#import "IncludedLinkLabelManager.h"

static NSString* const kBackgroundFillColorAttributeName = @"BackgroundFillColor";
static NSString* const kBackgroundLineWidthAttributeName = @"BackgroundLineWidth";
static NSString* const kBackgroundCornerRadiusAttributeName = @"BackgroundCornerRadius";


@interface IncludedLinkLabel ()
@property (nonatomic, copy) NSAttributedString *attributedText;
@property (nonatomic, copy) NSAttributedString *inactiveAttributedText;
@property (nonatomic, copy) NSAttributedString *renderedAttributedText;
@property (nonatomic, assign) CTFramesetterRef framesetter;
@property (nonatomic, strong) NSArray *links;
@property (nonatomic, strong) NSTextCheckingResult *activeLink;
@property (nonatomic, strong) NSDictionary *linkAttributes;
@property (nonatomic, strong) NSDictionary *activeLinkAttributes;
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
    [mutableActiveLinkAttributes setValue:(id)[[UIColor redColor] CGColor] forKey:(NSString *)kCTForegroundColorAttributeName];
    [mutableActiveLinkAttributes setValue:(id)[[UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.1f] CGColor] forKey:(NSString *)kBackgroundFillColorAttributeName];    
    [mutableActiveLinkAttributes setValue:(id)[NSNumber numberWithFloat:1.0f] forKey:(NSString *)kBackgroundLineWidthAttributeName];
    [mutableActiveLinkAttributes setValue:(id)[NSNumber numberWithFloat:5.0f] forKey:(NSString *)kBackgroundCornerRadiusAttributeName];

    self.activeLinkAttributes = [NSDictionary dictionaryWithDictionary:mutableActiveLinkAttributes];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (void)dealloc
{
    if (_framesetter) CFRelease(_framesetter);
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

            self.framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.renderedAttributedText);
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

- (void)addLinkToURL:(NSURL *)url withRange:(NSRange)range
{
    NSTextCheckingResult *result = [NSTextCheckingResult linkCheckingResultWithRange:range URL:url];
    [self addLinksWithTextCheckingResults:[NSArray arrayWithObject:result] attributes:self.linkAttributes];
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

   [self drawBackground:frame inRect:rect context:c];

    CFArrayRef lines = CTFrameGetLines(frame);
    NSInteger numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);

    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y);
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        CTLineDraw(line, c);
    }
    CFRelease(frame);
    CFRelease(path);
}

- (void)drawBackground:(CTFrameRef)frame
                inRect:(CGRect)rect
               context:(CGContextRef)c
{
    NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frame);
    CGPoint origins[[lines count]];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
    CFIndex lineIndex = 0;
    for (id line in lines) {
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = CTLineGetTypographicBounds((__bridge CTLineRef)line, &ascent, &descent, &leading) ;
        CGRect lineBounds = CGRectMake(0.0f, 0.0f, width, ascent + descent + leading) ;
        lineBounds.origin.x = origins[lineIndex].x;
        lineBounds.origin.y = origins[lineIndex].y;

        for (id glyphRun in (__bridge NSArray *)CTLineGetGlyphRuns((__bridge CTLineRef)line)) {
            NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes((__bridge CTRunRef) glyphRun);
            CGColorRef fillColor = (__bridge CGColorRef)[attributes objectForKey:kBackgroundFillColorAttributeName];
            CGFloat cornerRadius = [[attributes objectForKey:kBackgroundCornerRadiusAttributeName] floatValue];
            CGFloat lineWidth = [[attributes objectForKey:kBackgroundLineWidthAttributeName] floatValue];

            if (fillColor) {
                CGRect runBounds = CGRectZero;
                CGFloat ascent = 0.0f;
                CGFloat descent = 0.0f;

                runBounds.size.width = CTRunGetTypographicBounds((__bridge CTRunRef)glyphRun, CFRangeMake(0, 0), &ascent, &descent, NULL);
                runBounds.size.height = ascent + descent;

                CGFloat xOffset = CTLineGetOffsetForStringIndex((__bridge CTLineRef)line, CTRunGetStringRange((__bridge CTRunRef)glyphRun).location, NULL);
                runBounds.origin.x = origins[lineIndex].x + rect.origin.x + xOffset;
                runBounds.origin.y = origins[lineIndex].y + rect.origin.y;
                runBounds.origin.y -= descent;

                CGPathRef path = [[UIBezierPath bezierPathWithRoundedRect:CGRectInset(CGRectInset(runBounds, -1.0f, -3.0f), lineWidth, lineWidth) cornerRadius:cornerRadius] CGPath];
                CGContextSetLineJoin(c, kCGLineJoinRound);
                CGContextSetFillColorWithColor(c, fillColor);
                CGContextAddPath(c, path);
                CGContextFillPath(c);
            }
        }

        lineIndex++;
    }
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
        mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text
                                                                         attributes:[IncludedLinkLabelManager nsAttributedStringAttributesFromLabel:self]];
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
        if (!self.inactiveAttributedText) {
            self.inactiveAttributedText = [self.attributedText copy];
        }

        NSMutableAttributedString *mutableAttributedString = [self.inactiveAttributedText mutableCopy];
        [mutableAttributedString addAttributes:self.activeLinkAttributes range:_activeLink.range];
        self.attributedText = mutableAttributedString;

        [self setNeedsDisplay];
    } else if (self.inactiveAttributedText) {
        self.attributedText = self.inactiveAttributedText;
        self.inactiveAttributedText = nil;

        [self setNeedsDisplay];
    }
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

    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter,
                                                                   CFRangeMake(0, [self.attributedText length]),
                                                                   NULL,
                                                                   textRect.size,
                                                                   NULL);
    textSize = CGSizeMake(ceilf(textSize.width), ceilf(textSize.height));

    return textRect;
}

- (void)drawTextInRect:(CGRect)rect
{
    if (!self.attributedText) {
        [super drawTextInRect:rect];
        return;
    }
    NSAttributedString *originalAttributedText;
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(contextRef, CGAffineTransformIdentity);
    CGContextTranslateCTM(contextRef, 0.0f, rect.size.height);
    CGContextScaleCTM(contextRef, 1.0f, -1.0f);
    CFRange textRange = CFRangeMake(0, [self.attributedText length]);

    // Get the text rect
    CGRect textRect = [self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines];
    CGContextTranslateCTM(contextRef, 0.0f, rect.size.height - textRect.origin.y - textRect.size.height);

    [self drawFramesetter:self.framesetter
         attributedString:self.renderedAttributedText
                textRange:textRange
                   inRect:textRect
                  context:contextRef];

    if (originalAttributedText) {
        self.text = originalAttributedText;
    }
}
#pragma mark - UIGestureRecognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    self.activeLink = [self linkAtPoint:[touch locationInView:self]];
    return (self.activeLink != nil);
}

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] != UIGestureRecognizerStateEnded) {
        return;
    }

    if (self.activeLink) {
        NSTextCheckingResult *result = self.activeLink;
        self.activeLink = nil;

        if (result.resultType == NSTextCheckingTypeLink) {
            if ([self.delegate respondsToSelector:@selector(includedLinkLabel:didSelectLinkWithURL:)]) {
                [self.delegate includedLinkLabel:self didSelectLinkWithURL:result.URL];
            }
        }
    }
}


@end