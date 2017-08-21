//
//  Record.m
//  recoder
//
//  Created by hillliao on 15/8/23.
//  Copyright (c) 2015年 com.hfh. All rights reserved.
//

#import "Record.h"
#import <AudioToolbox/AudioQueue.h>


@interface Record (){

}

@end

@implementation Record

-(instancetype)init{
    self = [super init];
    if (self) {

    }
    return self;
}

static void AQInputCallback (void                   * inUserData,
                             AudioQueueRef          inAudioQueue,
                             AudioQueueBufferRef    inBuffer,
                             const AudioTimeStamp   * inStartTime,
                             UInt32          inNumPackets,
                             const AudioStreamPacketDescription * inPacketDesc)
{
    NSLog(@"AQInputCallback");
    Record * engine = (__bridge Record *) inUserData;
    if (inNumPackets > 0)
    {
        [engine processAudioBuffer:inBuffer withQueue:inAudioQueue];
    }
        AudioQueueEnqueueBuffer(inAudioQueue, inBuffer, 0, NULL);
}

-(void)initAQC
{
    memset(audioByte, 0, kByteslen);
    self.audioDataLength = 0;
    audioDataIndex = 0;
    ///设置音频参数
    mDataFormat.mSampleRate = 16000;//采样率
    mDataFormat.mFormatID = kAudioFormatLinearPCM;
    mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    mDataFormat.mChannelsPerFrame = 1;///单声道
    mDataFormat.mFramesPerPacket = 1;//每一个packet一侦数据
    mDataFormat.mBitsPerChannel = 16;//每个采样点16bit量化
    mDataFormat.mBytesPerFrame = 2 * mDataFormat.mChannelsPerFrame;
    mDataFormat.mBytesPerPacket = 2;
    ///创建一个新的从audioqueue到硬件层的通道
//    AudioQueueNewInput(&aqc.mDataFormat, AQInputCallback, (__bridge void *)(self), NULL, kCFRunLoopCommonModes,0, &aqc.queue);//使用当前线程播
    AudioQueueNewInput(&mDataFormat, AQInputCallback, (__bridge void *)self, nil, nil,0, &AudioQueue);//使用player的内部线程播
    ////添加buffer区
    for(int i=0;i<kNumberBuffers;i++)
    {
        // 函数功能：请求音频队列对象来分配一个音频队列缓存。
        int result =  AudioQueueAllocateBuffer(AudioQueue, 6400, &mBuffers[i]);
        NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d",i,result);
    }
}

- (void) start
{
    //得到AVAudioSession单例对象
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];//设置类别,表示该应用同时支持播放和录音
    [audioSession setActive:YES error:nil];//启动音频会话管理,此时会阻断后台音乐的播放.
    
    [self initAQC];

    int x = AudioQueueStart(AudioQueue, NULL);
    NSLog(@"%d",x);
    for(int i=0;i<kNumberBuffers;i++)
    {
        AudioQueueEnqueueBuffer(AudioQueue, mBuffers[i], 0, NULL);
    }
}

- (void) stop
{
    AudioQueueStop(AudioQueue, true);
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];         //一定要在录音停止以后再关闭音频会话管理（否则会报错），此时会延续后台音乐
    
    AudioQueueDispose(AudioQueue,true);
}

- (void) pause
{
    AudioQueuePause(AudioQueue);
}

- (Byte *)getBytes
{
    return audioByte;
}

- (void) processAudioBuffer:(AudioQueueBufferRef) buffer withQueue:(AudioQueueRef) queue
{
    NSLog(@"processAudioData :%u", (unsigned int)buffer->mAudioDataByteSize);
    NSData *data = [NSData dataWithBytes:(char *)buffer->mAudioData length:buffer->mAudioDataByteSize];
    if (self.AudioBufferCallBack) {
        self.AudioBufferCallBack(data);
    }
    //处理data：忘记oc怎么copy内存了，于是采用的C++代码，记得把类后缀改为.mm。同Play
    /*   //拼接成长的完整数据
    memcpy(audioByte+audioDataIndex, buffer->mAudioData, buffer->mAudioDataByteSize);
    audioDataIndex +=buffer->mAudioDataByteSize;
    self.audioDataLength = audioDataIndex;
     */
}

@end
