//
//  ViewController.m
//  TestDB
//
//  Created by huangshisong on 15/5/19.
//  Copyright (c) 2015年 huangshisong. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
#pragma mark ----创建数据表
    [Person createTableIfNotExists];
    NSLog(@"沙盒地址：%@",PATH_OF_DOCUMENT);
#pragma mark ----添加数据
    Person * item = [[Person alloc]init];
    item.name = @"张三";
    item.age = @"20";
    item.sex = @"男";
    item.address = @"成都";
    [item insertDB];
    item.name = @"李四";
    item.age = @"22";
    item.sex = @"女";
    item.address = @"北京";
    [item insertDB];

#pragma mark ----查询数据
    //查询所有
    NSArray * allPeople = [Person selectDBWithAllValue];
    [allPeople enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        //obj是字典 可以写成下面这种
        //NSDictionary * dic = obj;
        //Person * item = [Person objWithJsonDic:dic];
        
        Person * item = [Person objWithJsonDic:obj];
        NSLog(@"编号:%@  姓名:%@  年龄:%@  性别:%@  地址:%@ ",item.id,item.name,item.age,item.sex,item.address);
    }];
    //查询指定值
    NSArray * array = [Person selectDBWithKey:@"name" forValue:@"张三"];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Person * item = [Person objWithJsonDic:obj];
        NSLog(@"编号:%@  姓名:%@  年龄:%@  性别:%@  地址:%@ ",item.id,item.name,item.age,item.sex,item.address);
    }];
#pragma mark ----删除数据
    //删除所有数据
    [Person deleteDB];
    //删除指定数据
    [Person deleteDBWithKey:@"name" value:@"张三"];
#pragma mark ----修改数据
    //方法一将李四的年龄修改为50
    [Person updateDBWithKey:@"name" value:@"李四" updateKey:@"age" newValue:@"50"];
    
    //方法二 先查询 修改属性 删除原有数据 重新插入
    NSArray * data = [Person selectDBWithKey:@"name" forValue:@"李四"];
    [data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Person * item = [Person objWithJsonDic:obj];
        [Person deleteDBWithKey:@"name" value:@"李四"];
        item.address = @"四川成都";
        item.name = @"王五";
        item.sex = @"男";
        [item insertDB];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
