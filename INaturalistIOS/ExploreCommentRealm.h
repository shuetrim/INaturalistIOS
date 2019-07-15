//
//  ExploreCommentRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreComment.h"
#import "ExploreUserRealm.h"
#import "CommentVisualization.h"

@interface ExploreCommentRealm : RLMObject <CommentVisualization>

@property NSInteger commentId;
@property NSString *commentText;
@property ExploreUserRealm *commenter;
@property NSDate *commentedDate;

- (instancetype)initWithMantleModel:(ExploreComment *)model;

@end

RLM_ARRAY_TYPE(ExploreCommentRealm)
