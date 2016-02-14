//
//  NSIndexSet+MHD.h
//  ZChat
//
//  Created by ALEXEY LOBANOV on 13.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (MY)
- (NSArray *)indexPathsFromIndexesWithSection:(NSUInteger)section;
@end
