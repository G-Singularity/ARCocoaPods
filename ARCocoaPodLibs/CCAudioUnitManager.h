//
//  CCAudioUnitManager.h
//  CCAudioUnitCapture
//
//  Created by myth on 5/7/21.
//

#import <Foundation/Foundation.h>
#import "ARSingleton.h"
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 12 定义回调数据结构体
struct CCCaptureAudioData {
    void *data;
    int   size;
    UInt32 inNumberFrames;
    int64_t pts;
};
typedef struct CCCaptureAudioData* CCCaptureAudioDataRef;

#pragma mark - 13 定义把数据回调给外部的代理
@protocol CCAudioUnitManagerDelegate<NSObject>

@optional
- (void)receiveAudioDataByDevice:(CCCaptureAudioDataRef)audioDataRef;

@end

@interface CCAudioUnitManager : NSObject
SingletonH

@property (nonatomic, assign, readonly) BOOL isRunning;

@property (nonatomic, weak) id<CCAudioUnitManagerDelegate> delegate;

+ (instancetype)getInstance;
- (void)startAudioCapture;
- (void)stopAudioCapture;

- (void)stopRecordFile;
- (void)startRecordFile;
- (void)freeAudioUnit;

- (AudioStreamBasicDescription)getAudioDataFormat;

@end

NS_ASSUME_NONNULL_END
