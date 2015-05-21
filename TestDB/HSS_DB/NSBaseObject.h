//
//  NSBaseObject.h
//  ZJX
//
//  Created by huangshisong on 15/5/19.
//  Copyright (c) 2015年 huangshisong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBaseObject : NSObject{
        BOOL isInitSuccuss;
}
+ (id)objWithJsonDic:(NSDictionary *)dic;
- (id)jsonString;

+ (void)createTableIfNotExists;
+ (NSString*)tableName;
+ (void)deleteDBWithKey:(NSString *)key value:(NSString *)value;
+ (void)deleteDB;
- (void)insertDB;
+ (id)selectDBWithAllValue;
+ (id)selectDBWithKey:(NSString *)key forValue:(NSString *)value;
+ (void)updateDBWithKey:(NSString *)key
                  value:(NSString *)value
              updateKey:(NSString *)updateKey
               newValue:(NSString *)newValue;
@end
