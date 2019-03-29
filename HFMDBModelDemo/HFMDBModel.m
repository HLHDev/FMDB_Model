//
//  HFMDBModel.m
//  HFMDBModelDemo
//
//  Created by H&L on 2019/3/29.
//  Copyright © 2019 hzsmac. All rights reserved.
//

#import "HFMDBModel.h"
#import <objc/runtime.h>

/** SQLite五种数据类型 */
#define SQLTEXT     @"TEXT"
#define SQLINTEGER  @"INTEGER"
#define SQLREAL     @"REAL"
#define SQLBLOB     @"BLOB"
#define SQLNULL     @"NULL"

@implementation HFMDBModel

/** 获取kclass所有属性 */
+ (NSDictionary *)getAllProperties:(Class)kclass {
    NSMutableDictionary *propertyDict = [[NSMutableDictionary alloc] init];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(kclass, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        //获取属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        //        [proNames addObject:propertyName];
        //获取属性类型等参数
        NSString *propertyType = [NSString stringWithCString: property_getAttributes(property) encoding:NSUTF8StringEncoding];
        /*
         各种符号对应类型，部分类型在新版SDK中有所变化，如long 和long long
         c char         C unsigned char
         i int          I unsigned int
         l long         L unsigned long
         s short        S unsigned short
         d double       D unsigned double
         f float        F unsigned float
         q long long    Q unsigned long long
         B BOOL
         @ 对象类型 //指针 对象类型 如NSString 是@“NSString”
         
         
         64位下long 和long long 都是Tq
         SQLite 默认支持五种数据类型TEXT、INTEGER、REAL、BLOB、NULL
         因为在项目中用的类型不多，故只考虑了少数类型
         */
        if ([propertyType hasPrefix:@"T@"]) {
            propertyType = SQLTEXT;
        } else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]||[propertyType hasPrefix:@"Tq"]||[propertyType hasPrefix:@"TQ"]) {
            propertyType = SQLINTEGER;
            
        } else {
            propertyType = SQLREAL;
        }
        [propertyDict setValue:propertyType forKey:propertyName];
    }
    free(properties);
    
    return propertyDict;
}

/** 获取列名 */
+ (NSArray *)getColumNamesInTable:(NSString *)tableName
                       inDatabase:(FMDatabase *)db {
    NSMutableArray *columns = [NSMutableArray array];
    FMResultSet *resultSet = [db getTableSchema:tableName];
    while ([resultSet next]) {
        NSString *column = [resultSet stringForColumn:@"name"];
        [columns addObject:column];
    }
    [resultSet close];
    return [columns copy];
}

/**
 * 创建表 如果已经创建，返回YES
 */
+ (BOOL)createTableWithName:(NSString *)tableName
                 modelClass:(Class)kclass
                 primaryKey:(NSString *)primaryKey
                 inDatabase:(FMDatabase *)db {
    NSMutableString *columeAndTypes = [NSMutableString string];
    NSDictionary *dictProperties = [self getAllProperties:kclass];
    [dictProperties enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [columeAndTypes appendFormat:@"%@ %@,", key, obj];
    }];
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@ PRIMARY KEY(%@));",tableName, columeAndTypes, primaryKey];
    if (![db executeUpdate:sql]) {
        return NO;
    };
    
    NSMutableArray *columns = [NSMutableArray array];
    FMResultSet *resultSet = [db getTableSchema:tableName];
    while ([resultSet next]) {
        NSString *column = [resultSet stringForColumn:@"name"];
        [columns addObject:column];
    }
    
    NSArray *properties = [dictProperties allKeys];
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",columns];
    //过滤数组
    NSArray *resultArray = [properties filteredArrayUsingPredicate:filterPredicate];
    for (NSString *column in resultArray) {
        NSString *proType = [dictProperties objectForKey:column];
        NSString *fieldSql = [NSString stringWithFormat:@"%@ %@",column,proType];
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",NSStringFromClass(self.class),fieldSql];
        if (![db executeUpdate:sql]) {
            return NO;
        }
    }
    
    return YES;
}


+ (BOOL)insertModel:(id)model
            toTable:(NSString *)tableName
         toDatabase:(FMDatabase *)db {
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray  array];
    NSArray *columeNames = [self getColumNamesInTable:tableName inDatabase:db];
    for (int i = 0; i < columeNames.count; i++) {
        NSString *proname = [columeNames objectAtIndex:i];
        [keyString appendFormat:@"%@,", proname];
        [valueString appendString:@"?,"];
        id value = [model valueForKey:proname];
        if (!value) {
            value = @"";
        }
        [insertValues addObject:value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
    if ([db executeUpdate:sql withArgumentsInArray:insertValues]) {
        return YES;
    }
    return NO;
}

/** 批量保存对象 */
+ (BOOL)insertModels:(NSArray *)models
             toTable:(NSString *)tableName
          toDatabase:(FMDatabase *)db {
    if (models.count == 0) {
        return NO;
    }
    
    NSArray *columeNames = [self getColumNamesInTable:tableName inDatabase:db];
    for (id model in models) {
        NSMutableString *keyString = [NSMutableString string];
        NSMutableString *valueString = [NSMutableString string];
        NSMutableArray *insertValues = [NSMutableArray  array];
        for (int i = 0; i < columeNames.count; i++) {
            NSString *proname = [columeNames objectAtIndex:i];
            [keyString appendFormat:@"%@,", proname];
            [valueString appendString:@"?,"];
            id value = [model valueForKey:proname];
            if (!value) {
                value = @"";
            }
            [insertValues addObject:value];
        }
        [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
        [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
        
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
        if (![db executeUpdate:sql withArgumentsInArray:insertValues]) {
            return NO;
        }
    }
    return YES;
}

///** 通过条件删除数据 */
+ (BOOL)deleteObjectsInTable:(NSString *)tableName
                  inDatabase:(FMDatabase *)db
                    criteria:(nullable NSString *)criteria {
    if (criteria.length == 0) {
        return [self clearTable:tableName inDatabase:db];
    }
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ %@ ",tableName, criteria];
    return [db executeUpdate:sql];
}

+ (BOOL)clearTable:(NSString *)tableName inDatabase:(FMDatabase *)db {
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
    return [db executeUpdate:sql];
}

/** 查询全部数据 */
+ (NSArray *)selectAllModels:(Class)kclass
                     inTable:(NSString *)tableName
                  inDatabase:(FMDatabase *)db {
    return [self selectModels:kclass inTable:tableName inDatabase:db criteria:nil];
}

/** 通过条件查找数据 */
+ (NSArray *)selectModels:(Class)kclass
                  inTable:(NSString *)tableName
               inDatabase:(FMDatabase *)db
                 criteria:(nullable NSString *)criteria {
    NSMutableArray *resultArray = [NSMutableArray array];
    NSDictionary *dictProperties = [self getAllProperties:kclass];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
    if (criteria.length > 0) {
        NSString *sqlCriteria = [NSString stringWithFormat:@" %@", criteria];
        sql = [sql stringByAppendingString:sqlCriteria];
    }
    
    FMResultSet *resultSet = [db executeQuery:sql];
    while ([resultSet next]) {
        id model = [[kclass alloc] init];
        [dictProperties enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *columeName = (NSString *)key;
            NSString *columeType = (NSString *)obj;
            if ([columeType isEqualToString:SQLTEXT]) {
                [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
            } else {
                [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
            }
        }];
        [resultArray addObject:model];
        FMDBRelease(model);
    }
    [resultSet close];
    return resultArray;
}

+ (id)selectModel:(Class)kclass
          inTable:(NSString *)tableName
       inDatabase:(FMDatabase *)db
         criteria:(nullable NSString *)criteria {
    NSDictionary *dictProperties = [self getAllProperties:kclass];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
    if (criteria.length > 0) {
        NSString *sqlCriteria = [NSString stringWithFormat:@" %@", criteria];
        sql = [sql stringByAppendingString:sqlCriteria];
    }
    FMResultSet *resultSet = [db executeQuery:sql];
    if ([resultSet next]) {
        id model = [[kclass alloc] init];
        [dictProperties enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *columeName = (NSString *)key;
            NSString *columeType = (NSString *)obj;
            if ([columeType isEqualToString:SQLTEXT]) {
                [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
            } else {
                [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
            }
        }];
        [resultSet close];
        FMDBRelease(model);
        return model;
    }
    
    return nil;
}

+ (id)selectOneVaule:(NSString *)columeName
             inTable:(NSString *)tableName
          inDatabase:(FMDatabase *)db
            criteria:(NSString *)criteria {
    __block id object = nil;
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ %@", columeName, tableName ,criteria];
    FMResultSet *resultSet = [db executeQuery:sql];
    if (resultSet.next) {
        object = [resultSet objectForColumnIndex:0];
    }
    [resultSet close];
    return object;
}

@end
