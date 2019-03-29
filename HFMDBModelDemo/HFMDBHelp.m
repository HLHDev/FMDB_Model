//
//  HFMDBHelp.m
//  HFMDBModelDemo
//
//  Created by H&L on 2019/3/29.
//  Copyright © 2019 hzsmac. All rights reserved.
//

#import "HFMDBHelp.h"
#import "HFMDBModel.h"
#import "HPersonModel.h"


@implementation HFMDBHelp

+ (instancetype)shareInstance {
    static HFMDBHelp *dbHelp = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dbHelp = [[HFMDBHelp alloc] init];
    });
    return dbHelp;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initPersonDBDatabase];
    }
    return self;
}

- (void)initPersonDBDatabase {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *dbPath = [documentsDir stringByAppendingPathComponent:@"user.db"];
    NSLog(@"dbPath:%@",dbPath);
    _personQueue = [[FMDatabaseQueue alloc] initWithPath:dbPath];
    [_personQueue inDatabase:^(FMDatabase * _Nonnull db) {
        [HFMDBModel createTableWithName:person_db modelClass:[HPersonModel class] primaryKey:@"userId" inDatabase:db];
    }];
    
    [self checkUpdate:_personQueue version:1];
}

- (void)closePersonDBDatabase {
    if (_personQueue) {
        [_personQueue close];
        _personQueue = nil;
    }
}

- (void)checkUpdate:(FMDatabaseQueue *)queue version:(NSInteger)ver{
    NSInteger dbVersion = [self getDatabaseVersion:queue];
    if (dbVersion >= ver) {
        return;
    }
    switch (ver) {
        case 0:
            break;
    }
    [self setDatabaseVersion:queue version:ver];
}

- (NSInteger)getDatabaseVersion:(FMDatabaseQueue *)queue{
    __block NSInteger ver = 0;
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"pragma database_ver"];
        if ([rs next]) {
            ver = (uint32_t)[rs longLongIntForColumnIndex:0];
        }
        [rs close];
    }];
    return ver;
}

- (void)setDatabaseVersion:(FMDatabaseQueue *)queue version:(NSInteger)ver{
    [queue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"pragma database_ver = %ld", (long)ver];
        [db executeUpdate:sql];
    }];
}


@end
