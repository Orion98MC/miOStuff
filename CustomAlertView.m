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
	NSMutableArray *bottomViews = [NSMutableArray array];
	CGRect labelsFrame = CGRectNull;
	CGRect buttonsFrame = CGRectNull;
	
	BOOL capturingLabelsFrame = NO;

	// First we need to identify the alert buttons to move them down later
	for (UIView *view in self.subviews) {   		
		if ([view isKindOfClass:[UILabel class]] && (CGRectIsNull(labelsFrame) || capturingLabelsFrame)) {
			labelsFrame = CGRectUnion(labelsFrame, view.frame);
			capturingLabelsFrame = YES;
		} else {
			capturingLabelsFrame = NO;
		}
		
		if ([[[view class]description]isEqualToString:@"UIThreePartButton"]) {
			buttonsFrame = CGRectUnion(buttonsFrame, view.frame);
			[bottomViews addObject:view];
		}
	}
	
	// Only if the contentView is not empty
	if (contentView && !CGRectIsEmpty(contentView.frame)) {	
		CGFloat interSpace = CGRectIsNull(buttonsFrame) ? CGRectGetMinY(labelsFrame) : CGRectGetMinY(buttonsFrame) - CGRectGetMaxY(labelsFrame); // Space between last label and first button
		
		// Set content view frame according to the subviews it has
		CGRect contentBounds = contentView.bounds;
		contentView.frame = contentBounds;
		CGRect frame = contentView.frame;
		frame.origin.x = (abs(CGRectGetWidth(labelsFrame) - frame.size.width))/ 2 + CGRectGetMinX(labelsFrame);
		frame.origin.y = CGRectGetMaxY(labelsFrame) + interSpace/2;
		contentView.frame = frame;
	
		// add the contentView as subview
		if (!CGRectIsEmpty(contentView.frame)) {
			
			// Need to move the bottomViews down to make room for the contentView
			for (UIView *bottomView in bottomViews) {
				CGRect frame = bottomView.frame;
				frame.origin.y += contentView.frame.size.height;
				bottomView.frame = frame;
			}
			
			// Re adjust the view frame	and bounds with the new contentView height
			CGRect frame = self.frame;
			CGRect bounds = self.bounds;
			frame.size.height += contentView.frame.size.height;
			bounds.size.height += contentView.frame.size.height;
			frame.origin.y -= contentView.frame.size.height / 2;
			self.frame = frame;
			self.bounds = bounds;
			
			// Add the contentView subview
			[self addSubview:contentView];
		}
		// NSLog(@"Labels %@\nButtons %@\n", NSStringFromCGRect(labelsFrame), NSStringFromCGRect(buttonsFrame));
	}
	
	// TODO: adjust the view size to the total content size
	
//	if (adjustSizeToContent) {
//		CGFloat maxY = 0.0;
//		CGRect maxRect = CGRectZero;
//		maxRect = CGRectUnion(maxRect, labelsFrame);
//		maxRect = CGRectUnion(maxRect, contentView.frame);
//		maxRect = CGRectUnion(maxRect, buttonsFrame);
//		
//		NSLog(@"maxRect: %@", NSStringFromCGRect(maxRect));
//		NSLog(@"self: %@", NSStringFromCGRect(self.frame));
//
//		CGRect frame = self.frame;
//		frame.size.height = maxRect.size.height + 25;
//		frame.origin.y -= (frame.size.height - self.frame.size.height)/2;
//		NSLog(@"new frame: %@", NSStringFromCGRect(frame));
//		self.frame = frame;
//		CGRect bounds = self.bounds;
//		bounds.size.height = frame.size.height;
//		self.bounds = bounds;
//	}
	
}

@end
