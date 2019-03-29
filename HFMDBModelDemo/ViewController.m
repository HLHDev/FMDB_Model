//
//  ViewController.m
//  HFMDBModelDemo
//
//  Created by H&L on 2019/3/29.
//  Copyright © 2019 hzsmac. All rights reserved.
//

#import "ViewController.h"
#import "HFMDBHelp.h"
#import "HPersonModel.h"
#import "HFMDBModel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    /*
     fmdbmodel使用
     */
    HPersonModel *person = [self getPersonInfo];
    NSLog(@"%@",person.userName);
}

- (HPersonModel *)getPersonInfo {
    __block HPersonModel *person = nil;
    [[HFMDBHelp shareInstance].personQueue inDatabase:^(FMDatabase * _Nonnull db) {
        person = [HFMDBModel selectModel:[HPersonModel class] inTable:person_db inDatabase:db criteria:@"ORDER BY timeStamp DESC LIMIT 1"];
    }];
    return person;
}


@end
