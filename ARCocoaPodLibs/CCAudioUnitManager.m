//
//  CCAudioUnitManager.m
//  CCAudioUnitCapture
//
//  Created by myth on 5/7/21.
//

#import "CCAudioUnitManager.h"
#import <AudioToolbox/AudioToolbox.h>

#define kCCCAudioPCMFramesPerPacket 1
#define KCCCAudioBitsPerChannel 16

#define INPUT_BUS  1      ///< A I/O unit's bus 1 connects to input hardware (microphone).
#define OUTPUT_BUS 0      ///< A I/O unit's bus 0 connects to output hardware (speaker).

const static NSString *kModuleName = @"CCCAudioCapture";

static AudioUnit                    m_audioUnit;
static AudioBufferList              *m_buffList;
static AudioStreamBasicDescription  m_audioDataFormat;

uint32_t g_av_base_time = 100;

@interface CCAudioUnitManager()

@property (nonatomic, assign, readwrite) BOOL isRunning;

@end

@implementation CCAudioUnitManager
SingletonM

#pragma mark - 11 定义一个回调 AudioCaptureCallback
/// 回调
/// @param inRefCon 开发者自己定义的任何数据,一般将本类的实例传入,因为回调函数中无法直接调用OC的属性与方法,此参数可以作为OC与回调函数沟通的桥梁.即传入本类对象.
/// @param ioActionFlags 描述上下文信息
/// @param inTimeStamp 包含采样的时间戳
/// @param inBusNumber 调用此回调函数的总线数量
/// @param inNumberFrames 此次调用包含了多少帧数据
/// @param ioData 音频数据
static OSStatus AudioCaptureCallback(void                       *inRefCon,
                                     AudioUnitRenderActionFlags *ioActionFlags,
                                     const AudioTimeStamp       *inTimeStamp,
                                     UInt32                     inBusNumber,
                                     UInt32                     inNumberFrames,
                                     AudioBufferList            *ioData) {
#pragma mark - 11.1 回调函数中处理音频数据
    //AudioUnitRender 使用此函数将采集到的音频数据赋值给我们定义的全局变量m_buffList
    AudioUnitRender(m_audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, m_buffList);
    
    if (g_av_base_time == 0) {
        return noErr;
    }

#pragma mark - 13.1 把数据回调给外部的代理
    CCAudioUnitManager *manager = (__bridge CCAudioUnitManager *)inRefCon;

    Float64 currentTime = CMTimeGetSeconds(CMClockMakeHostTimeFromSystemUnits(inTimeStamp->mHostTime));
    int64_t pts = (int64_t)((currentTime - g_av_base_time) * 1000);
    
    /*  Test audio fps
     static Float64 lastTime = 0;
     Float64 currentTime = CMTimeGetSeconds(CMClockMakeHostTimeFromSystemUnits(inTimeStamp->mHostTime))*1000;
     NSLog(@"Test duration - %f",currentTime - lastTime);
     lastTime = currentTime;
     */
    
    void    *bufferData = m_buffList->mBuffers[0].mData;
    UInt32   bufferSize = m_buffList->mBuffers[0].mDataByteSize;
    
    //    NSLog(@"demon = %d",bufferSize);
    
    struct CCCaptureAudioData audioData = {
        .data           = bufferData,
        .size           = bufferSize,
        .inNumberFrames = inNumberFrames,
        .pts            = pts,
    };

    CCCaptureAudioDataRef audioDataRef = &audioData;

    if ([manager.delegate respondsToSelector:@selector(receiveAudioDataByDevice:)]) {
        [manager.delegate receiveAudioDataByDevice:audioDataRef];
    }
        
    return noErr;
}

#pragma mark - public
#pragma mark - 0 获取单例的方法，调用init方法
+ (instancetype)getInstance {
    return [[self alloc] init];
}

- (void)startAudioCapture {
    [self startAudioCaptureWithAudioUnit:m_audioUnit isRunning:&_isRunning];
}

- (void)startAudioCaptureWithAudioUnit:(AudioUnit)audioUnit isRunning:(BOOL *)isRunning {
    OSStatus status;
    if (*isRunning) {
        NSLog(@"%@:  %s - start recorder repeat \n",kModuleName,__func__);
        return;
    }
    
#pragma mark - 10. 开启audio unit
    status = AudioOutputUnitStart(audioUnit);
    if (status == noErr) {
        *isRunning        = YES;
        NSLog(@"%@:  %s - start audio unit success \n",kModuleName,__func__);
    }else {
        *isRunning  = NO;
        NSLog(@"%@:  %s - start audio unit failed \n",kModuleName,__func__);
    }
}

- (void)stopAudioCapture {
    [self stopAudioCaptureWithAudioUnit:m_audioUnit isRunning:&_isRunning];
}

- (void)stopAudioCaptureWithAudioUnit:(AudioUnit)audioUnit isRunning:(BOOL *)isRunning {
    if (*isRunning == NO) {
        NSLog(@"%@:  %s - stop capture repeat \n",kModuleName,__func__);
        return;
    }
    
    *isRunning = NO;
    if (audioUnit != NULL) {
#pragma mark - 14 停止audio unit
        OSStatus status = AudioOutputUnitStop(audioUnit);
        if (status != noErr){
            NSLog(@"%@:  %s - stop audio unit failed. \n",kModuleName,__func__);
        }else {
            NSLog(@"%@:  %s - stop audio unit successful",kModuleName,__func__);
        }
    }
}

#pragma mark - 15 释放资源
- (void)freeAudioUnit {
    [self freeAudioUnit:m_audioUnit];
    self.isRunning = NO;
}

- (void)freeAudioUnit:(AudioUnit)audioUnit {
    if (!audioUnit) {
        NSLog(@"%@:  %s - repeat call!",kModuleName,__func__);
        return;
    }
    
    OSStatus result = AudioOutputUnitStop(audioUnit);
    if (result != noErr){
        NSLog(@"%@:  %s - stop audio unit failed.",kModuleName,__func__);
    }
    
    result = AudioUnitUninitialize(m_audioUnit);
    if (result != noErr) {
        NSLog(@"%@:  %s - uninitialize audio unit failed, status : %d",kModuleName,__func__,result);
    }
    
    // It will trigger audio route change repeatedly
    result = AudioComponentInstanceDispose(m_audioUnit);
    if (result != noErr) {
        NSLog(@"%@:  %s - dispose audio unit failed. status : %d",kModuleName,__func__,result);
    }else {
        audioUnit = nil;
    }
}

#pragma mark - 其他
- (void)startRecordFile {
    
}

- (void)stopRecordFile {
    
}

- (AudioStreamBasicDescription)getAudioDataFormat {
    return m_audioDataFormat;
}

#pragma mark - 1 整体初始化：dispatch_once执行一次，
//传入音频流数据格式ASBD、格式ID、采样率、声道数、音频缓存大小、采样时间、流回调
- (instancetype)init {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instace = [super init];
        // Note: audioBufferSize couldn't more than durationSec max size.
        [_instace configInfoWithFormat:&m_audioDataFormat formatID:kAudioFormatLinearPCM sampleRate:44100 channelCount:1 bufferSize:2048 durationSec:0.02 callBack:AudioCaptureCallback];
    });
    return _instace;
}

#pragma mark - 2 具体初始化的方法
- (void)configInfoWithFormat:(AudioStreamBasicDescription *)dataFormat formatID:(UInt32)formatID sampleRate:(Float64)sampleRate channelCount:(UInt32)channelCount bufferSize:(int)bufferSize durationSec:(float)durationSec callBack:(AURenderCallback)callBack {
#pragma mark - 3 配置音频流数据格式ASBD
    [self configAudioToAudioFormat:dataFormat byParamFormatID:formatID sampleRate:sampleRate channelCount:channelCount];
    
#pragma mark - 4 设置采样时间
    //使用AVAudioSession可以设置采样时间,注意,在采样时间一定的情况下,我们设置的采样大小不能超过其最大值.
    //数据量（字节 / 秒）=（采样频率（Hz）* 采样位数（bit）* 声道数）/ 8
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:durationSec error:NULL];
    
#pragma mark - 5 配置Audio Unit
    m_audioUnit = [self configAudioUnitWithDataFormat:*dataFormat audioBufferSize:bufferSize callback:callBack];
}

#pragma mark - 3.1 详细配置音频流数据格式ASBD
- (void)configAudioToAudioFormat:(AudioStreamBasicDescription *)audioFormat byParamFormatID:(UInt32)formatID sampleRate:(Float64)sampleRate channelCount:(UInt32)channelCount {
    AudioStreamBasicDescription dataFormat = {0};
    UInt32 size = sizeof(dataFormat.mSampleRate);
    //Get hardware origin sample rate. (Recommended it)
    Float64 hardwareSampleRate = 0;
    //AudioSessionGetProperty 查询当前硬件指定属性的值
    //kAudioSessionProperty_CurrentHardwareSampleRate为查询当前硬件采样率
    //AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &hardwareSampleRate);
    //不过AudioSessionGetProperty在iOS7就被废弃了，改用AVAudioSession
    //获取当前硬件采样率
    hardwareSampleRate = [[AVAudioSession sharedInstance] sampleRate];
    
    //Manual set sample rate 手动设置
    dataFormat.mSampleRate = sampleRate;
    //或者设置为当前硬件采样率
    //dataFormat.mSampleRate = hardwareSampleRate;
    
    size = sizeof(dataFormat.mChannelsPerFrame);
    // Get hardware origin channels number. (Must refer to it)
    NSInteger hardwareNumberChannels = 0;
    //kAudioSessionProperty_CurrentHardwareInputNumberChannels为查询当前采集的声道数
    //AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels, &size, &hardwareNumberChannels);
    //在iOS7就被废弃了，改用AVAudioSession
    hardwareNumberChannels = [[AVAudioSession sharedInstance] inputNumberOfChannels];
    
    dataFormat.mChannelsPerFrame = channelCount;
    //dataFormat.mChannelsPerFrame = hardwareNumberChannels;
    
    //Set audio format 设置编码格式
    dataFormat.mFormatID = formatID;
    
    if (formatID == kAudioFormatLinearPCM) {
        //数据格式；（L/R，整形or浮点）
        dataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        //每个声道的采样深度
        dataFormat.mBitsPerChannel = KCCCAudioBitsPerChannel;
        //mBytesPerPacket: 每个Packet的Bytes数   mBytesPerFrame:每帧的Byte数
        dataFormat.mBytesPerPacket = dataFormat.mBytesPerFrame = (dataFormat.mBitsPerChannel / 8) * dataFormat.mChannelsPerFrame;
        //每个Packet的帧数
        dataFormat.mFramesPerPacket = kCCCAudioPCMFramesPerPacket;
    }
    memcpy(audioFormat, &dataFormat, sizeof(dataFormat));
    NSLog(@"%@:  %s - sample rate:%f, channel count:%d",kModuleName, __func__,sampleRate,channelCount);
}

#pragma mark - 5.1 详细配置Audio Unit
- (AudioUnit)configAudioUnitWithDataFormat:(AudioStreamBasicDescription)dataFormat audioBufferSize:(int)audioBufferSize callback:(AURenderCallback)callback {
#pragma mark - 6 创建Audio Unit
    AudioUnit audioUnit = [self createAudioUnitObject];
    if (!audioUnit) {
        return NULL;
    }
    
#pragma mark - 7 创建一个接收采集到音频数据的数据结构   AudioBufferList
    [self initCaptureAudioBufferWithAudioUnit:audioUnit channelCount:dataFormat.mChannelsPerFrame dataByteSize:audioBufferSize];
    
#pragma mark - 8 设置audio unit属性 AudioUnitSetProperty
    [self setAudioUnitPropertyWithAudioUnit:audioUnit dataFormat:dataFormat];
    
#pragma mark - 9 注册回调函数 接收音频数据
    [self initCaptureCallbackWithAudioUnit:audioUnit callback:callback];
    
    // Calls to AudioUnitInitialize() can fail if called back-to-back on different ADM instances. A fall-back solution is to allow multiple sequential calls with as small delay between each. This factor sets the max number of allowed initialization attempts.
    OSStatus status = AudioUnitInitialize(audioUnit);
    if (status != noErr) {
        NSLog(@"%@:  %s - couldn't init audio unit instance, status : %d \n",kModuleName,__func__,status);
    }
    return audioUnit;
}

#pragma mark - 6.1 创建Audio Unit
- (AudioUnit)createAudioUnitObject {
    AudioUnit audioUnit;
    //音频单元描述
    AudioComponentDescription audioDesc;
    
    //componentType:一个音频组件通用的独特的四字节码标识
    audioDesc.componentType = kAudioUnitType_Output;
    
    //componentSubType;//由上面决定，设置相应的类型
    audioDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    //kAudioUnitSubType_VoiceProcessingIO:做回声消除及增强人声的分类
    //kAudioUnitSubType_RemoteIO:原始未处理音频数据的分类
    
    //componentManufacturer;//厂商身份验证
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    //componentFlags;//没有明确的指定，设置0
    audioDesc.componentFlags        = 0;
    //componentFlagsMask;//没有明确的指定，设置0
    audioDesc.componentFlagsMask    = 0;
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
    //AudioComponentInstanceNew获取audio unit实例
    OSStatus status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    if (status != noErr)  {
        NSLog(@"%@:  %s - create audio unit failed, status : %d \n",kModuleName, __func__, status);
        return NULL;
    }else {
        return audioUnit;
    }
}

#pragma mark - 7.1 创建一个接收采集到音频数据的数据结构   AudioBufferList
- (void)initCaptureAudioBufferWithAudioUnit:(AudioUnit)audioUnit channelCount:(int)channelCount dataByteSize:(int)dataByteSize {
    // Disable AU buffer allocation for the recorder, we allocate our own.
    UInt32 flag = 0;
    
    //kAudioUnitProperty_ShouldAllocateBuffer 默认为true，它将创建一个回调函数中接收数据的buffer，
    //在这里设置为false，我们自己定义了一个bufferList用来接收采集到的音频数据。
    OSStatus status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, INPUT_BUS, &flag, sizeof(flag));
    if (status != noErr) {
        NSLog(@"%@:  %s - couldn't allocate buffer of callback, status : %d \n", kModuleName, __func__, status);
    }
    
    AudioBufferList *bufList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
    bufList->mNumberBuffers = 1;
    bufList->mBuffers[0].mNumberChannels = channelCount;
    bufList->mBuffers[0].mDataByteSize = dataByteSize;
    bufList->mBuffers[0].mData = (UInt32 *)malloc(dataByteSize);
    m_buffList = bufList;
}

#pragma mark - 8.1 设置audio unit属性
- (void)setAudioUnitPropertyWithAudioUnit:(AudioUnit)audioUnit dataFormat:(AudioStreamBasicDescription)dataFormat {
    OSStatus status;
    //kAudioUnitProperty_StreamFormat:通过先前创建的ASBD设置音频数据流的格式
    status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, INPUT_BUS, &dataFormat, sizeof(dataFormat));
    if (status != noErr) {
        NSLog(@"%@:  %s - set audio unit stream format failed, status : %d \n",kModuleName, __func__,status);
    }
    
    /*
     // remove echo but can't effect by testing.
     UInt32 echoCancellation = 0;
     AudioUnitSetProperty(m_audioUnit,
     kAUVoiceIOProperty_BypassVoiceProcessing,
     kAudioUnitScope_Global,
     0,
     &echoCancellation,
     sizeof(echoCancellation));
     */
    
    //kAudioOutputUnitProperty_EnableIO: 启用/禁用 对于 输入端/输出端
    UInt32 enableFlag = 1;
    //启用 enableFlag 输入端 kAudioUnitScope_Input，因为这里只是采集
    status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, INPUT_BUS, &enableFlag, sizeof(enableFlag));
    if (status != noErr) {
        NSLog(@"%@:  %s - could not enable input on AURemoteIO, status : %d \n",kModuleName, __func__, status);
    }
    
    UInt32 disableFlag = 0;
    //禁用 disableFlag 输出端 kAudioUnitScope_Output，因为这里只是采集
    status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, OUTPUT_BUS, &disableFlag, sizeof(disableFlag));
    if (status != noErr) {
        NSLog(@"%@:  %s - could not enable output on AURemoteIO, status : %d \n",kModuleName, __func__,status);
    }
}

#pragma mark - 9.1 注册回调函数 接收音频数据
- (void)initCaptureCallbackWithAudioUnit:(AudioUnit)audioUnit callback:(AURenderCallback)callback {
    AURenderCallbackStruct captureCallback;
    captureCallback.inputProc = callback;
    captureCallback.inputProcRefCon = (__bridge void *)self;
    OSStatus status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, INPUT_BUS, &captureCallback, sizeof(captureCallback));
    if (status != noErr) {
        NSLog(@"%@:  %s - Audio Unit set capture callback failed, status : %d \n",kModuleName, __func__,status);
    }
}

@end















