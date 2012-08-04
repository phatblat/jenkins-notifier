//
//  NSString+ListContains.m
//  HudsonGrowl
//
//  Created by Benjamin Broll on 14.11.10.
//
//  This source code is licensed under the terms of the BSD license.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import "NSString+ListContains.h"


@implementation NSString (ListContains)

- (BOOL) containsSubstringFromList:(NSArray *)list {
	BOOL wasSubstringFound = NO;
	
	for (NSString *substring in list) {
		if ([substring length] > 0) {
			if ([substring hasPrefix:@"\""] && [substring hasSuffix:@"\""]) {
				// perform an exact match
				NSRange range;
				range.location = 1;
				range.length = [substring length]-2;
				
				substring = [substring substringWithRange:range];
				NSRange matchRange = [self rangeOfString:substring options:NSCaseInsensitiveSearch];
				if (matchRange.location == 0 && matchRange.length == [substring length]) {
					wasSubstringFound = YES;
					break;
				}
			} else {
				// perform a substring match
				NSRange range = [self rangeOfString:substring options:NSCaseInsensitiveSearch];
				if (range.location != NSNotFound) {
					wasSubstringFound = YES;
					break;
				}
			}
		}
	}
	
	return wasSubstringFound;
}

@end
