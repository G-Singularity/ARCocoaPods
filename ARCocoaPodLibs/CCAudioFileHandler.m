//
//  CCAudioFileHandler.m
//  CCAudioUnitCapture
//
//  Created by myth on 5/7/21.
//

#import "CCAudioFileHandler.h"

@implementation CCAudioFileHandler
SingletonM

+ (instancetype)getInstance {
    return [[self alloc] init];
}

/**
* Start / Stop record By Audio Converter.
*/
-(void)startVoiceRecordByAudioUnitByAudioConverter:(nullable AudioConverterRef)audioConverter needMagicCookie:(BOOL)isNeedMagicCookie audioDesc:(AudioStreamBasicDescription)audioDesc {
    
}

-(void)stopVoiceRecordAudioConverter:(nullable AudioConverterRef)audioConverter needMagicCookie:(BOOL)isNeedMagicCookie {
    
}

/**
* Write audio data to file.
*/
- (void)writeFileWithInNumBytes:(UInt32)inNumBytes ioNumPackets:(UInt32)ioNumPackets inBuffer:(const void *)inBuffer inPacketDesc:(nullable const AudioStreamPacketDescription *)inPacketDesc {
    
}

@end
