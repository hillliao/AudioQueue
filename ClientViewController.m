//
//  ClientViewController.m
//  AudioQueue
//
//  Created by hillliao on 2017/8/21.
//  Copyright © 2017年 hillliao. All rights reserved.
//

#import "ClientViewController.h"
#import "GCDAsyncSocket.h"
#import "Record.h"

@interface ClientViewController ()<GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UITextField *ipTF;
@property (weak, nonatomic) IBOutlet UITextField *portTF;
@property (weak, nonatomic) IBOutlet UITextField *msgTF;
@property (weak, nonatomic) IBOutlet UITextView *infoTV;

@property (strong, nonatomic) Record* record;
@property (strong, nonatomic) GCDAsyncSocket* socket;
@end

@implementation ClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
//对InfoTextView添加提示内容
-(void)addText:(NSString*)text{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.infoTV.text = [self.infoTV.text stringByAppendingString:text];
        if (self.infoTV.text.length > 600) {
            self.infoTV.text = @"";
        }
    });
}
- (IBAction)deleteTVtext:(UIButton *)sender {
    self.infoTV.text = @"";
    [self.ipTF resignFirstResponder];
}
- (IBAction)connectionAct:(UIButton *)sender {
    dispatch_queue_t queue = dispatch_queue_create("com.appcoda.queueClientSocket", NULL);
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:queue];
    if ([self.socket connectToHost:self.ipTF.text onPort:[self.portTF.text integerValue] error:nil]) {
        [self addText:[NSString stringWithFormat:@"开始连接 %@  %@",self.ipTF.text,self.portTF.text]];
    }else{
        [self addText:@"连接失败"];
    }

}
- (IBAction)disconnectAct:(UIButton *)sender {
    [self.socket disconnect];
    [self addText:@"断开连接"];
    if (!self.record) {
        self.record = [[Record alloc] init];
    }
    [self.record stop];
}
- (IBAction)sendMsgAct:(UIButton *)sender {
    if (!self.record) {
        self.record = [[Record alloc] init];
    }
    [self.record start];
    __weak typeof(self) weak_self = self;
    self.record.AudioBufferCallBack = ^(NSData *data){
        [weak_self.socket writeData:data withTimeout:-1 tag:0];
        [weak_self addText:[NSString stringWithFormat:@"write %zd",data.length]];
    };
    
}
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    [self addText:[NSString stringWithFormat:@"连接服务器 %@",host]];
    [self.socket readDataWithTimeout:-1 tag:0];
}
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *msg =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self addText:msg];
    [self.socket readDataWithTimeout:-1 tag:0];
}
@end
