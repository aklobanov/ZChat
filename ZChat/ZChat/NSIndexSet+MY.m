//
//  NSIndexSet+MHD.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 13.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "NSIndexSet+MY.h"

@implementation NSIndexSet (MY)
- (NSArray *)indexPathsFromIndexesWithSection:(NSUInteger)section
{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}
@end
