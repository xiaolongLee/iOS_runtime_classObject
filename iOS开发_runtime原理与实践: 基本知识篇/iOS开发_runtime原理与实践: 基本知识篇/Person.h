//
//  Person.h
//  iOS开发_runtime原理与实践: 基本知识篇
//
//  Created by Mac-Qke on 2019/7/15.
//  Copyright © 2019 Mac-Qke. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject{
    NSString *_country;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) double height;
@property (nonatomic, assign) double weight;
@property (nonatomic, copy) NSString *sex;
@end

NS_ASSUME_NONNULL_END
