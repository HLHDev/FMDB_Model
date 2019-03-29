//
//  HFMDBModel.h
//  HFMDBModelDemo
//
//  Created by H&L on 2019/3/29.
//  Copyright © 2019 hzsmac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

NS_ASSUME_NONNULL_BEGIN

@interface HFMDBModel : NSObject

/**
 * 创建表 如果已经创建，返回YES
 * primaryKey:可以是一个也可以是多个 @“userId” @"userId, groupId"
 */
+ (BOOL)createTableWithName:(NSString *)tableName
                 modelClass:(Class)kclass
                 primaryKey:(NSString *)primaryKey
                 inDatabase:(FMDatabase *)db;

/** 插入单个model对象 */
+ (BOOL)insertModel:(id)model
            toTable:(NSString *)tableName
         toDatabase:(FMDatabase *)db;

/** 批量插入model对象 */
+ (BOOL)insertModels:(NSArray *)models
             toTable:(NSString *)tableName
          toDatabase:(FMDatabase *)db;

/** 通过条件删除数据
 * criteria: 过滤条件 @"WHERE userId= ORDER BY timestamp DESC LIMIT 1"
 */
+ (BOOL)deleteObjectsInTable:(NSString *)tableName
                  inDatabase:(FMDatabase *)db
                    criteria:(nullable NSString *)criteria;

/** 清空表中的所有数据 */
+ (BOOL)clearTable:(NSString *)tableName inDatabase:(FMDatabase *)db;

/** 查询全部数据 */
+ (NSArray *)selectAllModels:(Class)kclass
                     inTable:(NSString *)tableName
                  inDatabase:(FMDatabase *)db;

/** 通过条件查找数据 */
+ (NSArray *)selectModels:(Class)kclass
                  inTable:(NSString *)tableName
               inDatabase:(FMDatabase *)db
                 criteria:(nullable NSString *)criteria;

/** 通过条件查找数据 如果查询结果有多条也只返回第一条*/
+ (id)selectModel:(Class)kclass
          inTable:(NSString *)tableName
       inDatabase:(FMDatabase *)db
         criteria:(nullable NSString *)criteria;

/** 通过条件查找数据 如果查询结果有多条也只返回第一条*/
+ (id)selectOneVaule:(NSString *)columeName
             inTable:(NSString *)tableName
          inDatabase:(FMDatabase *)db
            criteria:(NSString *)criteria;

@end

NS_ASSUME_NONNULL_END
