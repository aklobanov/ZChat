//
//  ViewController.h
//  ZChat
//
//  Created by ALEXEY LOBANOV on 04.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessages.h"

@interface MessageViewController : JSQMessagesViewController <JSQMessagesComposerTextViewPasteDelegate>
@end

