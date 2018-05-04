//
//  RxWeakWrapper.h
//  guard
//
//  Created by 黎书胜 on 2017/10/27.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RxWeakWrapper : NSObject
-(id)initWithObj:(id)ref;
@property(weak,nonatomic) id ref;
@property (strong, nonatomic) NSString* refClass;
@property (strong, nonatomic) NSValue* unsafeRef;
@end
