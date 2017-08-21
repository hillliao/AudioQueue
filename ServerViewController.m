//
//  ViewController.m
//  AudioQueue
//
//  Created by hillliao on 2017/8/18.
//  Copyright © 2017年 hillliao. All rights reserved.
//

#import "ServerViewController.h"
#import "GCDAsyncSocket.h"
#import "player.h"

@interface ServerViewController ()<GCDAsyncSocketDelegate>
//端口
@property (weak, nonatomic) IBOutlet UITextField *portTF;
//消息
@property (weak, nonatomic) IBOutlet UITextField *msgTF;
//信息显示
@property (weak, nonatomic) IBOutlet UITextView *infoTV;

@property (strong, nonatomic)GCDAsyncSocket *serverSocket;
@property (strong, nonatomic)GCDAsyncSocket *clientSocket;
@property (strong, nonatomic)Player *player;

@end

@implementation ServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    if (self.player == nil) {
        self.player = [[Player alloc] init];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//对InfoTextView添加提示内容
-(void)addText:(NSString*)text{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.infoTV.text = [self.infoTV.text stringByAppendingString:text];
        if (self.infoTV.text.length > 600) {
            self.infoTV.text = @"";
        }
    });
}
- (IBAction)deleteTVtext:(id)sender {
    self.infoTV.text = @"";
}
//监听
- (IBAction)listeningAct:(UIButton *)sender {
    dispatch_queue_t queue = dispatch_queue_create("com.appcoda.queueServerSocket", NULL);
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:queue];
    if ([self.serverSocket acceptOnPort:[self.portTF.text integerValue] error:nil]) {
        [self addText:@"监听成功"];
    }else{
        [self addText:@"监听失败"];
    }
}
- (IBAction)sendAct:(UIButton *)sender {
    NSData *data = [self.msgTF.text dataUsingEncoding:NSUTF8StringEncoding];
    if (self.clientSocket) {
        [self.clientSocket writeData:data withTimeout:-1 tag:0];
    }
}

-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    //当接收到新的Socket连接时执行
    [self addText:@"连接成功"];
    [self addText:[NSString stringWithFormat:@"连接地址 %@",newSocket.connectedHost]];
    [self addText:[NSString stringWithFormat:@"端口号 %d",newSocket.connectedPort]];
    
    self.clientSocket = newSocket;
    //第一次开始读取Data
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self addText:[NSString stringWithFormat:@"readData %zd %@",data.length,message]];
    [self.player.data appendData:data];
    if (!self.player.playFlage && self.player.data.length >= data.length*2) {
        [self.player stop];
        [self.player start];
        self.player.playFlage = YES;
    }
    [sock readDataWithTimeout:-1 tag:0];
}
@end
