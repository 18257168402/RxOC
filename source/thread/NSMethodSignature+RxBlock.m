//
//  NSMethodSignature+Block.m
//  easylib
//
//  Created by 黎书胜 on 2018/2/5.
//  Copyright © 2018年 黎书胜. All rights reserved.
//

#import "NSMethodSignature+RxBlock.h"


// Block internals.
typedef NS_OPTIONS(int, GCBlockFlags) {
    GCBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    GCBlockFlagsHasSignature          = (1 << 30)
};
typedef struct GC_Block {
    __unused Class isa;
    GCBlockFlags flags;
    __unused int reserved;
    void (__unused *invoke)(struct GC_Block *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        // requires AspectBlockFlagsHasCopyDisposeHelpers
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        // requires AspectBlockFlagsHasSignature
        const char *signature;
        const char *layout;
    } *descriptor;
    // imported variables
} *GCBlockRef;


@implementation NSMethodSignature(RxBlock)
+(NSMethodSignature *)rx_methodSignatureWithBlock:(id)block{
    GCBlockRef layout = (__bridge void *)block;
    if (!(layout->flags & GCBlockFlagsHasSignature)) {
        //NSString *description = [NSString stringWithFormat:@"The block %@ doesn't contain a type signature.", block];
        return nil;
    }
    void *desc = layout->descriptor;
    desc += 2 * sizeof(unsigned long int);
    if (layout->flags & GCBlockFlagsHasCopyDisposeHelpers) {
        desc += 2 * sizeof(void *);
    }
    if (!desc) {
       // NSString *description = [NSString stringWithFormat:@"The block %@ doesn't has a type signature.", block];
        return nil;
    }
    const char *signature = (*(const char **)desc);
    return [NSMethodSignature signatureWithObjCTypes:signature];
}
@end
