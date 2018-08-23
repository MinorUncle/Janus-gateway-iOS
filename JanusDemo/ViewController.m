//
//  ViewController.m
//  GJJanusDemo
//
//  Created by melot on 2018/3/14.
//

#import "ViewController.h"
#import "VideoCallViewController.h"
#include <sys/sysctl.h>
@interface ViewController ()
{
    UITextField* _input;
    UIButton* _startBtn;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildUI];

    
    // Do any additional setup after loading the view, typically from a nib.
}


-(void)buildUI{
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    //    //去掉 bar 下面有一条黑色的线
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];

    CGRect bound = self.view.bounds;
    int height = 50;
    CGRect rect = CGRectMake(50, 0, 50, height);
    rect.origin.y = (bound.size.height - height)*0.5;
    rect.size.width = bound.size.width - 2*rect.origin.x;
    _input = [[UITextField alloc]initWithFrame:rect];
    _input.placeholder = @"请输入用户名";
    _input.keyboardType = UIKeyboardTypePhonePad;
    _input.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:_input];
    
    rect.origin.y = CGRectGetMaxY(rect) + 20;
    _startBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _startBtn.layer.borderWidth = 1;
    _startBtn.layer.borderColor = [UIColor grayColor].CGColor;
    _startBtn.layer.cornerRadius = 5;
    _startBtn.frame = rect;
    [_startBtn addTarget:self action:@selector(start:) forControlEvents:UIControlEventTouchUpInside];
    [_startBtn setTitle:@"start" forState:UIControlStateNormal];
    [_startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:_startBtn];
}
-(void)start:(UIButton*)btn{
    if (_input.text.length <= 3) {
        _input.placeholder = @"请输入只是三个字的名称";
        _input.text = @"";
        return;
    }
    VideoCallViewController* controller = [[VideoCallViewController alloc]init];
    controller.userName = _input.text;
    [self.navigationController pushViewController:controller animated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    [self setupConnent];
//}




@end

