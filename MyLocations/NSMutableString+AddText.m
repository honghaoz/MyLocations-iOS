//
//  NSMutableString+AddText.m
//  MyLocations
//
//  Created by Zhang Honghao on 2/4/14.
//  Copyright (c) 2014 org-honghao. All rights reserved.
//

#import "NSMutableString+AddText.h"

@implementation NSMutableString (AddText)

- (void)addText:(NSString *)text withSeparator:(NSString *)separator
{
    if (text != nil) {
        if ([self length] > 0) {
            [self appendString:separator];
        }
        [self appendString:text];
    }
}

@end
