//
//  IDCardLayer.m
//  testOCR
//
//  Created by lei.qiao on 16/3/22.
//  Copyright © 2016年 LeiQiao. All rights reserved.
//

#import "IDCardLayer.h"

@implementation IDCardLayer

-(void) drawInContext:(CGContextRef)ctx
{
    CGContextSetRGBStrokeColor(ctx, 1, 0, 0, 1);
    
    CGContextMoveToPoint(ctx, 60, 1);
    CGContextAddLineToPoint(ctx, 1, 1);
    CGContextAddLineToPoint(ctx, 1, 60);
    CGContextStrokePath(ctx);
    
    CGContextMoveToPoint(ctx, self.frame.size.width-60-2, 1);
    CGContextAddLineToPoint(ctx, self.frame.size.width-2, 1);
    CGContextAddLineToPoint(ctx, self.frame.size.width-2, 60);
    CGContextStrokePath(ctx);
    
    CGContextMoveToPoint(ctx, 1, self.frame.size.height-60-2);
    CGContextAddLineToPoint(ctx, 1, self.frame.size.height-2);
    CGContextAddLineToPoint(ctx, 60, self.frame.size.height-2);
    CGContextStrokePath(ctx);
    
    CGContextMoveToPoint(ctx, self.frame.size.width-2, self.frame.size.height-60-2);
    CGContextAddLineToPoint(ctx, self.frame.size.width-2, self.frame.size.height-2);
    CGContextAddLineToPoint(ctx, self.frame.size.width-60-2, self.frame.size.height-2);
    CGContextStrokePath(ctx);
}

@end
