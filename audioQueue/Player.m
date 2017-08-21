//
//  Player.m
//  RawAudioDataPlayer
//
//  Created by hillliao on 2015/8/24.
//  Copyright (c) 2015年 SamYou. All rights reserved.
//

#import "Player.h"

@interface Player (){
    BOOL stopDly;
}
    

@end

@implementation Player

-(instancetype)init{
    self = [super init];
    if (self) {
        pcmDataBuffer = (Byte *)malloc(EVERY_READ_LENGTH);
        synlock = [[NSLock alloc] init];
        self.data = [NSMutableData data];
        self.playFlage = NO;
        stopDly = NO;
    }
    return self;
}

- (void) start
{
    //得到AVAudioSession单例对象
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];//设置类别,表示该应用同时支持播放和录音
    [audioSession setActive:YES error:nil];//启动音频会话管理,此时会阻断后台音乐的播放.
    
    [self initAudio];
    NSLog(@"onbutton1clicked");
    AudioQueueStart(audioQueue, NULL);
    for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
    {
        [self readPCMAndPlay:audioQueue buffer:audioQueueBuffers[i]];
    }
}

- (void) stop
{
    AudioQueueStop(audioQueue, true);
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];         //一定要在录音停止以后再关闭音频会话管理（否则会报错），此时会延续后台音乐
    
    AudioQueueDispose(audioQueue,true);
}

#pragma mark -
#pragma mark player call back
/*
 试了下其实可以不用静态函数，但是c写法的函数内是无法调用[self ***]这种格式的写法，所以还是用静态函数通过void *input来获取原类指针
 这个回调存在的意义是为了重用缓冲buffer区，当通过AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);函数放入queue里面的音频文件播放完以后，通过这个函数通知
 调用者，这样可以重新再使用回调传回的AudioQueueBufferRef
 */
static void AudioPlayerAQInputCallback(void *input, AudioQueueRef outQ, AudioQueueBufferRef outQB)
{
//    NSLog(@"AudioPlayerAQInputCallback");
    Player *player = (__bridge Player *)input;
    [player readPCMAndPlay:outQ buffer:outQB];
}

-(void)initAudio
{
    ///设置音频参数
    audioDescription.mSampleRate = 16000;//采样率
    audioDescription.mFormatID = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioDescription.mChannelsPerFrame = 1;///单声道
    audioDescription.mFramesPerPacket = 1;//每一个packet一侦数据
    audioDescription.mBitsPerChannel = 16;//每个采样点16bit量化
    audioDescription.mBytesPerFrame = 2 * audioDescription.mChannelsPerFrame;
    audioDescription.mBytesPerPacket = 2;
    
    ///创建一个新的从audioqueue到硬件层的通道
    //	AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, self, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &audioQueue);///使用当前线程播
    AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, (__bridge void *)self, nil, nil, 0, &audioQueue);//使用player的内部线程播
    ////添加buffer区
    for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
    {
        int result =  AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);///创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
        NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d",i,result);
    }
}
//int count = 0;
-(void)readPCMAndPlay:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB
{
    [synlock lock];
    //    int readLength = fread(pcmDataBuffer, 1, EVERY_READ_LENGTH, file);//读取文件
    NSInteger readLength = [self makedatarange:pcmDataBuffer];
//    NSLog(@"read raw data size = %zd",readLength);

    outQB->mAudioDataByteSize = (int)readLength;
    Byte *audiodata = (Byte *)outQB->mAudioData;
    for(int i=0;i<readLength;i++)
    {
        audiodata[i] = pcmDataBuffer[i];
    }
    /*
     将创建的buffer区添加到audioqueue里播放
     AudioQueueBufferRef用来缓存待播放的数据区，AudioQueueBufferRef有两个比较重要的参数，AudioQueueBufferRef->mAudioDataByteSize用来指示数据区大小，AudioQueueBufferRef->mAudioData用来保存数据区
     */
    AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
    [synlock unlock];
}

-(NSInteger)makedatarange:(Byte*)buff
{
    if (stopDly) {
        stopDly = NO;  //改善会哔哔哔哔的杂声
        return 0;
    }else{
        if (self.data.length >= EVERY_READ_LENGTH) {
//            NSLog(@"self.data.length    %zd",self.data.length);
            [self.data getBytes:buff range:NSMakeRange(0, EVERY_READ_LENGTH)];
            [self.data replaceBytesInRange:NSMakeRange(0, EVERY_READ_LENGTH) withBytes:NULL length:0];
            return EVERY_READ_LENGTH;
        }else{
            NSInteger len = self.data.length;
            [self.data getBytes:buff range:NSMakeRange(0, self.data.length)];
            [self.data resetBytesInRange:NSMakeRange(0, self.data.length)];
            [self.data setLength:0];
            self.playFlage = NO;
            stopDly = YES;
            NSLog(@"self.data.length    %zd",self.data.length);
            return len;
    }
    }
    
}
@end
