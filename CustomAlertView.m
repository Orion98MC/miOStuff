/*
 * CustomAlertView
 *
 * (c) Thierry Passeron under MIT License
 *
 */

#import "CustomAlertView.h"

@interface CustomAlertView ()
- (CGMutablePathRef)mutableRoundedRectPathInContext:(CGContextRef)context rect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius;
@end

@implementation CustomAlertView
@synthesize contentView, borderColor;

#pragma mark Life cycle methods

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		super.backgroundColor = [UIColor clearColor];
		bgColor = [[UIColor blackColor]retain];
		borderColor = [[UIColor colorWithWhite:0.7 alpha:1.0]retain];
	}
	return self;
}

- (void)dealloc {
	NSLog(@"dealloc");
	[bgColor release];
	[borderColor release];
	[contentView release];
	[super dealloc];
}


#pragma mark Setters

- (void)setBackgroundColor:(UIColor *)color {
	if (![bgColor isEqual:color]) {
		[bgColor release];
		bgColor = [color retain];
	}
}


#pragma mark View methods

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	// Note: I don't get it but it seems to be not antialiasing the rounded gradient...
	CGContextSetAllowsAntialiasing(context, true);
	CGContextSetShouldAntialias(context, true);
	
	CGFloat lineWidth = 2.0;
	CGFloat shadowOffsetY = 5.0;
	CGFloat shadowBlur = 3.0;
	CGFloat cornerRadius = 8.0;
	CGFloat shadowHeight = shadowOffsetY + shadowBlur;
	UIColor *shadowColor = [UIColor colorWithWhite:0.08 alpha:0.6];
	
	CGRect viewRect = CGRectMake(rect.origin.x + lineWidth, rect.origin.y + lineWidth, rect.size.width - lineWidth*2, rect.size.height - lineWidth*2 - shadowHeight);
	CGMutablePathRef viewRoundedRect = [self mutableRoundedRectPathInContext:context rect:viewRect cornerRadius:cornerRadius];

	// Fill with shadow
	CGContextSetFillColorWithColor(context, [bgColor CGColor]);	
	CGContextSaveGState(context);
	CGContextSetShadowWithColor(context, CGSizeMake(0, shadowOffsetY), shadowBlur, [shadowColor CGColor]);
	CGContextAddPath(context, viewRoundedRect);
	CGContextDrawPath(context, kCGPathFill);
	CGContextRestoreGState(context);

	// Clip to rounded rect
	CGContextSaveGState(context);
	CGContextAddPath(context, viewRoundedRect);
	CGContextClip(context);

	// Gradient
	CGFloat components[8] = { 
		1.0, 1.0, 1.0, 0.6, 
		1.0, 1.0, 1.0, 0.12 
	};
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, components, NULL, 2);
	
	CGRect clip = CGRectMake(-rect.size.width * 0.3/2, -30, rect.size.width * 1.3, 30 * 2);
	CGContextAddEllipseInRect(context, clip);
	CGContextClip(context);
	
	CGContextDrawLinearGradient(context, gradient, rect.origin, CGPointMake(rect.origin.x, 30), 0);
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorspace);
	
	// Stroke rounded border
	CGContextRestoreGState(context);
	CGContextSetLineWidth(context, lineWidth);
	CGContextSetStrokeColorWithColor(context, [borderColor CGColor]);
	CGContextAddPath(context, viewRoundedRect);
	CGContextDrawPath(context, kCGPathStroke);
	
	CGPathRelease(viewRoundedRect);
}

- (CGMutablePathRef)mutableRoundedRectPathInContext:(CGContextRef)context rect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius {
	CGMutablePathRef roundedRectPath = CGPathCreateMutable();
	CGPathMoveToPoint(roundedRectPath, NULL, rect.origin.x + cornerRadius, rect.origin.y);
	CGPathAddArc(roundedRectPath, NULL, CGRectGetMaxX(rect) - cornerRadius, CGRectGetMinY(rect) + cornerRadius,	cornerRadius, -M_PI/2, 0, NO);
	CGPathAddArc(roundedRectPath, NULL, CGRectGetMaxX(rect) - cornerRadius, CGRectGetMaxY(rect) - cornerRadius,	cornerRadius, 0, M_PI/2, NO);
	CGPathAddArc(roundedRectPath, NULL, CGRectGetMinX(rect) + cornerRadius, CGRectGetMaxY(rect) - cornerRadius,	cornerRadius, M_PI/2, M_PI, NO);
	CGPathAddArc(roundedRectPath, NULL, CGRectGetMinX(rect) + cornerRadius, CGRectGetMinY(rect) + cornerRadius, cornerRadius, M_PI, 3*M_PI/2, NO);
	CGPathCloseSubpath(roundedRectPath);
	return roundedRectPath;
}

- (void)layoutSubviews {
  if (self.frame.origin.x == 0) { // I know ... hmm
    return;
  }
    
  CGRect beforeFrame = CGRectNull;
  NSMutableArray *toBeMovedDown = [NSMutableArray array];
  
  for (UIView *v in self.subviews) {
    if (NSEqualRanges([[[v class]description]rangeOfString:@"Button" options:NSCaseInsensitiveSearch],
                      (NSRange){NSNotFound, 0})) {
      if (v != self.contentView) {
        if ([v isKindOfClass:[UIImageView class]]) {
          v.alpha = 0.0;
        } else
          beforeFrame = CGRectUnion(beforeFrame, v.frame);
      }
    } else {
      if (v != self.contentView) {
        [toBeMovedDown addObject:v];
      }
    }      
  }
  
  if (self.contentView == nil) {
    return;
  }
    
  if ([self.subviews indexOfObject:self.contentView] == NSNotFound) {
    // Add contentView
    [self addSubview:self.contentView];
    // Position
    CGRect contentFrame = self.contentView.frame;
    contentFrame.origin.y = beforeFrame.origin.y + beforeFrame.size.height;
    contentFrame.origin.x = self.bounds.size.width / 2.0 - contentFrame.size.width / 2.0;
    self.contentView.frame = contentFrame;
  }
    
  if (toBeMovedDown.count) {
    CGRect contentFrame = self.contentView.frame;
    for (UIView *button in toBeMovedDown) {
      CGRect frame = button.frame;
      frame.origin.y += contentFrame.size.height;
      button.frame = frame;
    }
    // Resize self
    CGRect newFrame = self.frame;
    newFrame.size.height += contentFrame.size.height;
    newFrame.origin.y -= contentFrame.size.height / 2;
    self.frame = newFrame;
  }

}

@end
