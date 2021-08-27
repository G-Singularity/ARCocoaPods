//
//  CCAudioFileHandler.h
//  CCAudioUnitCapture
//
//  Created by myth on 5/7/21.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ARSingleton.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCAudioFileHandler : NSObject
SingletonH

+ (instancetype)getInstance;

/**
* Write audio data to file.
*/
- (void)writeFileWithInNumBytes:(UInt32)inNumBytes ioNumPackets:(UInt32)ioNumPackets inBuffer:(const void *)inBuffer inPacketDesc:(nullable const AudioStreamPacketDescription *)inPacketDesc;

#pragma mark - Audio Queue
/**
* Start / Stop record By Audio Queue.
*/
//- (void)startVoiceRecordByAudioQueue:(AudioQueueRef)audioQueue isNeedMagicCookie:(BOOL)isNeedMagicCookie audioDesc:(AudioStreamBasicDescription)audioDesc;
//
//- (void)stopVoiceRecordByAudioQueue:(AudioQueueRef)audioQueue needMagicCookie:(BOOL)isNeedMagicCookie;

/**
* Start / Stop record By Audio Converter.
*/
-(void)startVoiceRecordByAudioUnitByAudioConverter:(nullable AudioConverterRef)audioConverter needMagicCookie:(BOOL)isNeedMagicCookie audioDesc:(AudioStreamBasicDescription)audioDesc;
-(void)stopVoiceRecordAudioConverter:(nullable AudioConverterRef)audioConverter needMagicCookie:(BOOL)isNeedMagicCookie;

@end

NS_ASSUME_NONNULL_END
