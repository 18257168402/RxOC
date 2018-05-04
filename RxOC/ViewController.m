//
//  ViewController.m
//  RxOC
//
//  Created by 黎书胜 on 2018/5/4.
//  Copyright © 2018年 黎书胜. All rights reserved.
//

#import "ViewController.h"
#import "RxOC.h"

@interface TestKVO:NSObject
@property (assign) NSInteger intValue;
@end
@implementation TestKVO
@end

@interface ViewController ()
@property (strong, nonatomic) TestKVO* mTestKVO;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mTestKVO = [[TestKVO alloc] init];
    self.mTestKVO.intValue = 100;

    // Do any additional setup after loading the view, typically from a nib.
    UIButton* btn1 = [[UIButton alloc] initWithFrame:CGRectMake(50, 50, 100, 50)];
    btn1.backgroundColor = [UIColor grayColor];
    [btn1 setTitle:@"最简单rx形式" forState:UIControlStateNormal];
    [self.view addSubview:btn1];
    [btn1 addTarget:self action:@selector(onClickBtn1) forControlEvents:UIControlEventTouchUpInside];

    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(50, 150, 100, 50)];
    btn2.backgroundColor = [UIColor grayColor];
    [btn2 setTitle:@"KVO无需注销" forState:UIControlStateNormal];
    [self.view addSubview:btn2];
    [btn2 addTarget:self action:@selector(onClickBtn2) forControlEvents:UIControlEventTouchUpInside];


    UIButton *btn3 = [[UIButton alloc] initWithFrame:CGRectMake(50, 250, 100, 50)];
    btn3.backgroundColor = [UIColor grayColor];
    [btn3 setTitle:@"notification" forState:UIControlStateNormal];
    [self.view addSubview:btn3];
    [btn3 addTarget:self action:@selector(onClickBtn3) forControlEvents:UIControlEventTouchUpInside];

    //其他使用查看RxOCTests.h文件
}
-(void)onClickBtn3{
    [[NSNotificationCenter defaultCenter] rx_observeNotificationForName:@"testNotify" object:nil]
            .subcribe(^(NSNotification * value){
                NSLog(@">>>>NSNotification:%@",value.name);
            });
    [[NSNotificationCenter defaultCenter] postNotificationName:@"testNotify" object:nil];
}

-(void)onClickBtn2{
    id<IRxSubscription> subs = [self.mTestKVO rx_observeOnKey:@"intValue"].subcribe(^(RXObserveObject *obj){
        NSLog(@">>>keypath:%@ value:%@",obj.keypath, obj.values[NSKeyValueChangeNewKey]);
    });

    self.mTestKVO.intValue = 1024;
    [subs unsubscribe];//取消监听
}

-(void)onClickBtn1{
    [RxOC create:^(id<IRxEmitter> emt){
        NSLog(@"source thread:%d", [NSThread currentThread].isMainThread);
        [emt onNext:@"hello rxoc!"];
        [emt onComplete];
    }].subcribeOn(ScheduleOnIO)
    .observeOn(ScheduleOnMain)
    .subcribe(^(NSString *value){
        NSLog(@"onNext thread:%d", [NSThread currentThread].isMainThread);
        NSLog(@"onNext value:%@",value);
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
