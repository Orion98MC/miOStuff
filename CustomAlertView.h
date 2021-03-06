/*
 * CustomAlertView
 *
 * A custom alert view where you can add a content view and change background color and border color
 *
 * Usage:
 *
 *		#import "CustomAlertView.h"
 *
 *		[...]
 *   	CustomAlert *alert = [[[CustomAlertView alloc]initWithTitle:@"Welcome" 
 *																									 message:@"Now you can make custom alerts :)" 
 *																									delegate:self 
 *																				 cancelButtonTitle:nil 
 *																				 otherButtonTitles:@"Ok", nil]autorelease];
 *		alert.backgroundColor = [UIColor blueColor];
 *    alert.borderColor = [UIColor redColor];
 *
 *    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
 *    alert.contentView = [activity autorelease];
 *		[activity startAnimating];
 *
 *		[alert show];
 *
 *
 * Rem: The contentView is centered horizontaly in the alert view
 *
 *
 * (c) Thierry Passeron under MIT License
 *
 */

#import <UIKit/UIKit.h>

@interface CustomAlertView : UIAlertView {	
	UIView *contentView;
	UIColor *borderColor;	
	
	@private
	UIColor *bgColor;
}

@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) UIColor *borderColor;

@end
