//
//  NSBaseObject.m
//  ZJX
//
//  Created by huangshisong on 15/5/19.
//  Copyright (c) 2015年 huangshisong. All rights reserved.
//

#import "NSBaseObject.h"
#import <objc/runtime.h>
#import "FMDB.h"
#import "NSDictionaryAdditions.h"
#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define DBPATH [PATH_OF_DOCUMENT stringByAppendingPathComponent:@"db.sqlite"]
#define debugLog(...) NSLog(__VA_ARGS__)

@implementation NSBaseObject
#pragma mark ------dic--->models-----
+ (id)objWithJsonDic:(NSDictionary *)dic {
    return [[[self class] alloc] initWithJsonDic:dic];
}

- (id)initWithJsonDic:(NSDictionary*)dic {
    if (self = [super init]) {
        isInitSuccuss = NO;
        [self updateWithJsonDic:dic];
        if (!isInitSuccuss) {
            return nil;
        }
    }
    return self;
}

- (void)updateWithJsonDic:(NSDictionary *)dic {
    isInitSuccuss = NO;
    if (dic != nil && [dic isKindOfClass:[NSDictionary class]]) {
        isInitSuccuss = YES;
    }
    if (isInitSuccuss) {
        [self updateAllValue:self dic:dic];
    }
}

- (void)updateAllValue:(id)weak dic:(NSDictionary *)dic{
    if (![NSStringFromClass(((NSBaseObject*)weak).superclass) isEqualToString:@"NSBaseObject"]) {
        [self updateAllValue:((NSBaseObject*)weak).superclass dic:dic];
    }
    
    unsigned int propertyCount; //成员变量个数
    Ivar *vars = class_copyIvarList(((NSBaseObject*)weak).class, &propertyCount);
    
    NSString *key=nil;
    for(int i = 0; i < propertyCount; i++) {
        
        Ivar thisIvar = vars[i];
        key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];  //获取成员变量的名字
        if ([key hasPrefix:@"_"]) {
            key = [key substringFromIndex:1];
        }
        id value = [dic objectForKey:key];
        
        // see Objective-C Runtime Programming Guide > Type Encodings.
        const char * ivarType = ivar_getTypeEncoding(thisIvar);
        if (strcmp(ivarType, "c") == 0 || strcmp(ivarType, "@\"NSString\"") == 0) {
            value = [dic getStringValueForKey:key defaultValue:@""];
            [self setValue:value forKey:key];
        } else if (strcmp(ivarType, "d") == 0){
            double va = [dic getDoubleValueForKey:key defaultValue:0.];
            [self setValue:[NSNumber numberWithDouble:va] forKey:key];
        } else if (strcmp(ivarType, "i") == 0){
            int va = [dic getIntValueForKey:key defaultValue:0];
            [self setValue:[NSNumber numberWithInt:va] forKey:key];
        } else if (strcmp(ivarType, "f") == 0){
            float va = [dic getFloatValueForKey:key defaultValue:0];
            [self setValue:[NSNumber numberWithFloat:va] forKey:key];
        } else if (strcmp(ivarType, "B") == 0){
            BOOL va = [dic getIntValueForKey:key defaultValue:0];
            [self setValue:[NSNumber numberWithBool:va] forKey:key];
        } else {
            NSString * va = [NSString stringWithUTF8String:ivarType];
            va = [va stringByReplacingOccurrencesOfString :@"@\"" withString:@""];
            va = [va stringByReplacingOccurrencesOfString :@"\"" withString:@""];
            Class class = NSClassFromString(va);
            if (class && [class isSubclassOfClass:[NSBaseObject class]]) {
                NSDictionary * dictionary = [dic getDictionaryForKey:key];
                id value = [class objWithJsonDic:dictionary];
                [self setValue:value forKey:key];
            }
        }
    }
    
}


- (id) copy {
    id co = [[self.class alloc] init];
    unsigned int propertyCount = 0;
    objc_property_t * propertyList = class_copyPropertyList([self class], &propertyCount);
    for (int i=0; i<propertyCount;i++) {
        objc_property_t *thisProperty = propertyList + i;
        NSString * key = [NSString stringWithUTF8String:property_getName(*thisProperty)];
        id value = [self valueForKey:key];
        if (value) {
            [co setValue:value forKey:key];
        }
    }
    return co;
}

- (void) copyfrom:(NSBaseObject*)object {
    unsigned int propertyCount = 0;
    objc_property_t * propertyList = class_copyPropertyList([self class], &propertyCount);
    for (int i=0; i<propertyCount;i++) {
        objc_property_t *thisProperty = propertyList + i;
        NSString * key = [NSString stringWithUTF8String:property_getName(*thisProperty)];
        id value = [object valueForKey:key];
        if (value) {
            [self setValue:value forKey:key];
        }
    }
}

- (BOOL)isEqualTo:(NSBaseObject*)object {
    BOOL isEqual = YES;
    if (![self isKindOfClass:object.class]) {
        return NO;
    }
    unsigned int propertyCount = 0;
    objc_property_t * propertyList = class_copyPropertyList([self class], &propertyCount);
    for (int i=0; i<propertyCount;i++) {
        objc_property_t *thisProperty = propertyList + i;
        NSString * key = [NSString stringWithUTF8String:property_getName(*thisProperty)];
        id value = [self valueForKey:key];
        id value2 = [object valueForKey:key];
        
        if (![value isEqual:value2]) {
            isEqual = NO;
        }
    }
    return isEqual;
}
#pragma mark ------models-->dic------
- (id)jsonString {
    NSMutableDictionary * mdic = [NSMutableDictionary dictionary];
    unsigned int propertyCount = 0;
    objc_property_t * propertyList = class_copyPropertyList([self class], &propertyCount);
    for (int i=0; i<propertyCount;i++) {
        objc_property_t *thisProperty = propertyList + i;
        NSString * key = [NSString stringWithUTF8String:property_getName(*thisProperty)];
        id value = [self valueForKey:key];
        if (value) {
            if ([value isKindOfClass:[NSString class]]) {
                NSString * str = value;
                if ([str isEqualToString:@"0"]) {
                    continue;
                }
            } if ([value isKindOfClass:[NSNumber class]]) {
                NSNumber * num = value;
                if (num.intValue == 0) {
                    continue;
                }
            }
            [mdic setObject:value forKey:key];
        }
    }
    return mdic;
}

#pragma mark ------DB
+ (NSString*)tableName {
    return [NSString stringWithFormat:@"tb_%@", NSStringFromClass([self class])];
}

#pragma mark -----创建表------
+ (void)createTableIfNotExists {
    NSMutableArray * arr = [NSMutableArray array];
    unsigned int propertyCount = 0;
    objc_property_t * propertyList = class_copyPropertyList([self class], &propertyCount);
    for (int i=0; i<propertyCount; i++) {
        objc_property_t *thisProperty = propertyList + i;
        NSString * key = [NSString stringWithUTF8String:property_getName(*thisProperty)];
        if ([key isEqualToString:@"id"]) {
            continue;
        }
        NSString * str = [NSString stringWithFormat:@"'%@' VARCHAR(100)",key];
        [arr addObject:str];
    }
    NSString * str = [NSString stringWithFormat:@"%@",[arr componentsJoinedByString:@","]];
    //判断数据库中是否已经存在这个表，如果不存在则创建该表
    FMDatabase * db = [FMDatabase databaseWithPath:DBPATH];
    if ([db open]) {
        if(![db tableExists:self.tableName])
        {
            NSString * sql =[NSString stringWithFormat: @"CREATE TABLE '%@' ('id' INTEGER PRIMARY KEY AUTOINCREMENT  NOT NULL , %@)",self.tableName,str];
            //NSString * sql = @"CREATE TABLE 'cityName' ('id' INTEGER PRIMARY KEY AUTOINCREMENT  NOT NULL , 'city' VARCHAR(30))";
            BOOL res = [db executeUpdate:sql];
            if (!res) {
                debugLog(@"error when creating db table");
            } else {
                debugLog(@"succ to creating db table");
            }
            [db close];
        }
    }
    
}
#pragma mark -----插入数据 增------
- (void)insertDB {
    NSMutableArray * arr = [NSMutableArray array];
    unsigned int propertyCount = 0;
    objc_property_t * propertyList = class_copyPropertyList([self class], &propertyCount);
    NSMutableString * str = [NSMutableString string];
    NSMutableArray * valueArr = [NSMutableArray array];
    NSMutableArray * KeyArr = [NSMutableArray array];
    for (int i=0; i<propertyCount;i++) {
        objc_property_t *thisProperty = propertyList + i;
        NSString * key = [NSString stringWithUTF8String:property_getName(*thisProperty)];
        if ([key isEqualToString:@"id"]) {
            continue;
        }
        id value = [self valueForKey:key];
        [str appendString:@"?,"];
        [KeyArr addObject:key];
        [valueArr addObject:value?value:@""];
        [arr addObject:key];
    }
    FMDatabase * db = [FMDatabase databaseWithPath:DBPATH];
    if ([db open]) {
        NSString * sql =[NSString stringWithFormat: @"REPLACE into %@ (%@) values(%@) ",[[self class] tableName],[KeyArr componentsJoinedByString:@","],[str substringToIndex:str.length-1] ];
        
        BOOL res = [db executeUpdate:sql withArgumentsInArray:valueArr];
        if (!res) {
            debugLog(@"error to insert data");
        } else {
            debugLog(@"succ to insert data");
        }
        [db close];
    }
    
}
#pragma mark -----删除数据 删------
/**
 *  删除指定数据
 *
 *  @param key   key
 *  @param value key对应的值
 */
+ (void)deleteDBWithKey:(NSString *)key value:(NSString *)value{
    FMDatabase * db = [FMDatabase databaseWithPath:DBPATH];
    if ([db open]) {
         NSString * sql =[NSString stringWithFormat: @"delete from %@ where %@ = ? ",self.tableName,key];
        BOOL res = [db executeUpdate:sql,value];
        if (!res) {
            debugLog(@"error to delete db data");
        } else {
            debugLog(@"succ to deleta db data");
        }
        [db close];
    }
}
/**
 *  删除所有数据
 */
+ (void)deleteDB{
    FMDatabase * db = [FMDatabase databaseWithPath:DBPATH];
    if ([db open]) {
        NSString * sql =[NSString stringWithFormat: @"delete from %@",self.tableName];
        BOOL res = [db executeUpdate:sql];
        if (!res) {
            debugLog(@"error to delete db data");
        } else {
            debugLog(@"succ to deleta db data");
        }
        [db close];
    }
}

#pragma mark -----查询数据 查------
+ (id)selectDBWithKey:(NSString *)key forValue:(NSString *)value{
    NSMutableArray * arr= [[NSMutableArray alloc]init];
    FMDatabase * db = [FMDatabase databaseWithPath:DBPATH];
    if ([db open]) {
        NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ like ?",self.tableName,key];
        NSString * str = [NSString stringWithFormat:@"%%%@%%",value];
        FMResultSet * rs = [db executeQuery:sql,str];
        while ([rs next]) {
            unsigned int propertyCount = 0;
            objc_property_t * propertyList = class_copyPropertyList([self class], &propertyCount);
            NSMutableDictionary * dic = [[NSMutableDictionary alloc]init];
            for (int i=0; i<propertyCount;i++) {
                objc_property_t *thisProperty = propertyList + i;
                NSString * key = [NSString stringWithUTF8String:property_getName(*thisProperty)];
                [dic setObject:[rs stringForColumn:key] forKey:key];
            }
            [arr addObject:dic];
        }
        [db close];
    }
    return arr;
}
+ (id)selectDBWithAllValue{
    NSMutableArray * arr= [[NSMutableArray alloc]init];
    FMDatabase * db = [FMDatabase databaseWithPath:DBPATH];
    if ([db open]) {
        NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@",self.tableName];
        FMResultSet * rs = [db executeQuery:sql];
        while ([rs next]) {
            unsigned int propertyCount = 0;
            objc_property_t * propertyList = class_copyPropertyList([self class], &propertyCount);
            NSMutableDictionary * dic = [[NSMutableDictionary alloc]init];
            for (int i=0; i<propertyCount;i++) {
                objc_property_t *thisProperty = propertyList + i;
                NSString * key = [NSString stringWithUTF8String:property_getName(*thisProperty)];
                [dic setObject:[rs stringForColumn:key] forKey:key];
            }
            [arr addObject:dic];
        }
        [db close];
    }
    return arr;
}
/**
 *  修改数据
 *
 *  @param key       条件字段
 *  @param value     条件值
 *  @param updateKey 更新字段
 *  @param newValue  更新值
 */
+ (void)updateDBWithKey:(NSString *)key
                  value:(NSString *)value
              updateKey:(NSString *)updateKey
               newValue:(NSString *)newValue{
    FMDatabase * db = [FMDatabase databaseWithPath:DBPATH];
    if ([db open]) {
        NSString * sql =[NSString stringWithFormat: @"update %@ set %@ = ? WHERE %@ = ?  ",self.tableName,updateKey,key];
        BOOL res = [db executeUpdate:sql,newValue,value];
        if (!res) {
            debugLog(@"error to update db data");
        } else {
            debugLog(@"succ to update db data");
        }
        [db close];
    }

}

@end
