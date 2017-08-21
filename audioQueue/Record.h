//
//  Record.h
//  recoder
//
//  Created by hillliao on 15/8/23.
//  Copyright (c) 2015年 com.hfh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>

// use Audio Queue
#define kNumberBuffers 4
#define kSamplingRate 16000
#define kNumberChannels 1
#define kBitsPerChannels 16
#define kBytesPerFrame 4
#define kByteslen 999999

@interface Record : NSObject
{
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef               AudioQueue;
    AudioQueueBufferRef         mBuffers[kNumberBuffers];
    AudioFileID                 outputFile;
    
    Byte audioByte[kByteslen];
    long audioDataIndex;
}
- (void) start;
- (void) stop;
- (void) pause;
- (Byte *) getBytes;
- (void) processAudioBuffer:(AudioQueueBufferRef) buffer withQueue:(AudioQueueRef) queue;

@property (nonatomic, assign) NSInteger audioDataLength;
@property(nonatomic, copy) void (^AudioBufferCallBack)(NSData *data);       //录音数据回调

@end
