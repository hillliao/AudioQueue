//
//  Player.h
//  RawAudioDataPlayer
//
//  Created by hillliao on 2015/8/24.
//  Copyright (c) 2015年 SamYou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h> 
#import <AVFoundation/AVFoundation.h>


#define QUEUE_BUFFER_SIZE 2 //队列缓冲个数
#define EVERY_READ_LENGTH 1600 //每次从文件读取的长度
#define MIN_SIZE_PER_FRAME 2000 //每侦最小数据长度

@interface Player : NSObject{
    AudioStreamBasicDescription audioDescription;///音频参数
    AudioQueueRef audioQueue;//音频播放队列
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE];//音频缓存
    NSLock *synlock ;///同步控制
    Byte *pcmDataBuffer;//pcm的读文件数据区
}
@property(nonatomic) BOOL playFlage;
@property(strong,nonatomic) NSMutableData *data;

- (void) start;
- (void) stop;

@end
