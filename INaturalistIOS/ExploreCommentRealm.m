//
//  ExploreCommentRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreCommentRealm.h"

@implementation ExploreCommentRealm

- (instancetype)initWithMantleModel:(ExploreComment *)model {
    if (self = [super init]) {
        self.commentId = model.commentId;
        self.commentText = model.commentText;
        self.commentedDate = model.commentedDate;
        if (model.commenter) {
            self.commenter = [[ExploreUserRealm alloc] initWithMantleModel:model.commenter];
        }
    }
    return self;
}

+ (NSString *)primaryKey {
    return @"commentId";
}

- (NSString *)body {
    return self.commentText;
}

- (NSDate *)createdAt {
    return self.commentedDate;
}

- (NSURL *)userIconUrl {
    return self.commenter.userIcon;
}

- (NSInteger)userId {
    return self.commenter.userId;
}

- (NSString *)userName {
    return self.commenter.login;
}

@end
