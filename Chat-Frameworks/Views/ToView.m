//
//  ToView.m
//  AcaniChat
//
//  Created by Krystof Celba on 16.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ToView.h"

@implementation ToView
@synthesize toInput;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.backgroundColor = [UIColor whiteColor];
		UILabel *toLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 9.0f, 30.0f, 22.f)];
		toLabel.text = @"To:";
		toLabel.textColor = [UIColor grayColor];
        toInput = [[UITextField alloc] initWithFrame:CGRectMake(55.0f, 9.0f, 234.0f, 22.0f)];
		[self addSubview:toLabel];
		[self addSubview:toInput];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
