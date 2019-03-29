//
//  HFMDBHelp.h
//  HFMDBModelDemo
//
//  Created by H&L on 2019/3/29.
//  Copyright © 2019 hzsmac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

#define person_db     @"personDB"

NS_ASSUME_NONNULL_BEGIN

@interface HFMDBHelp : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, strong) FMDatabaseQueue *personQueue;

- (void)closePersonDBDatabase;


@end

NS_ASSUME_NONNULL_END
