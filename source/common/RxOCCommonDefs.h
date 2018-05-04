//
//  EasyCommonDefs.h
//  easylib
//
//  Created by 黎书胜 on 2017/12/2.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#ifndef RxOCCommonDefs_h
#define RxOCCommonDefs_h

#define RXWEAKSELF_DECLARE __weak typeof(self) weakself=self;
#define RXWEAKDECL(NAME) __weak typeof(self) NAME = self;
#define RXWEAKDECLWITH(NAME,VAR) __weak typeof(VAR) NAME = VAR;

#define CommonIORxTrans  ^(RxOC* rx){\
return rx.subcribeOn(ScheduleOnIO)\
.observeOn(ScheduleOnMain);\
}\

#ifdef DEBUG

#define RxLog(fmt,...){\
NSString* _fmt = [NSString stringWithFormat:@"[%@] %@ ( at:%@:%d )",@"V",fmt,[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__];\
NSString* _log =[NSString stringWithFormat:_fmt,##__VA_ARGS__,nil];\
NSLog(@"%@",_log);\
\
}

#define RxLogT(tag,fmt,...) {\
NSString* _fmt = [NSString stringWithFormat:@"[%@] %@ ( at:%@ line: %d )",tag,fmt,[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__];\
NSString* _log =[NSString stringWithFormat:_fmt,##__VA_ARGS__,nil];\
NSLog(@"%@",_log);\
\
}
#else

#define RxLogT(tag,fmt,...)
#define RxLog(fmt,...)
#define RxLogT(tag,fmt,...)
#endif

#endif /* EasyCommonDefs_h */
