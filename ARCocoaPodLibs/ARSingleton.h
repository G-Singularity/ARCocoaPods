//
//  ARSingleton.h
//  CCAudioUnitCapture
//
//  Created by myth on 5/7/21.
//

#ifndef ARSingleton_h
#define ARSingleton_h

// .h文件的实现
#define SingletonH
// .m文件的实现
#if __has_feature(objc_arc) // 是ARC
#define SingletonM \
static id _instace = nil; \
+ (id)allocWithZone:(struct _NSZone *)zone \
{ \
if (_instace == nil) { \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instace = [super allocWithZone:zone]; \
}); \
} \
return _instace; \
} \
\
+ (id)copyWithZone:(struct _NSZone *)zone \
{ \
return _instace; \
} \
\
+ (id)mutableCopyWithZone:(struct _NSZone *)zone \
{ \
return _instace; \
}
#else // 不是ARC
#define SingletonM \
static id _instace = nil; \
+ (id)allocWithZone:(struct _NSZone *)zone \
{ \
if (_instace == nil) { \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instace = [super allocWithZone:zone]; \
}); \
} \
return _instace; \
} \
\
- (id)init \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instace = [super init]; \
}); \
return _instace; \
} \
\
- (oneway void)release \
{ \
\
} \
\
- (id)retain \
{ \
return self; \
} \
\
- (NSUInteger)retainCount \
{ \
return 1; \
} \
+ (id)copyWithZone:(struct _NSZone *)zone \
{ \
return _instace; \
} \
\
+ (id)mutableCopyWithZone:(struct _NSZone *)zone \
{ \
return _instace; \
}
#endif

#endif /* ARSingleton_h */
