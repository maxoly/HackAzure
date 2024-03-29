/*
 Copyright 2010 Microsoft Corp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "UIViewController+ShowError.h"


@implementation UIViewController (ShowError)

- (void)showError:(NSError*)error
{
	[self showError:error withTitle:@"Error"];
}

- (void)showError:(NSError*)error withTitle:(NSString*)title
{
/*	if([error code] == 401)
	{
		UIViewController* root = [self.navigationController.viewControllers objectAtIndex:0];
		[self.navigationController popToRootViewControllerAnimated:YES];
		[root performSelector:@selector(logout:) withObject:error afterDelay:0.3];
		return;
	}	*/
	
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
													message:[error localizedDescription]
												   delegate:nil 
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
}



@end
