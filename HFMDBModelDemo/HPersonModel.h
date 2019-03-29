//
//  HPersonModel.h
//  HFMDBModelDemo
//
//  Created by H&L on 2019/3/29.
//  Copyright © 2019 hzsmac. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, Sex){
    men = 0,
    women
};

@interface HPersonModel : NSObject

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *userAge;
@property (nonatomic, assign) Sex userSex;

@end

NS_ASSUME_NONNULL_END
