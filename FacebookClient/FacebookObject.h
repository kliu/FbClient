//
//  FacebookObject.h
//  Swift
//
//  Created by John Wright on 2/7/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FacebookObjectConnectionTypeHome  @"home"
#define FacebookObjectConnectionTypeFeed  @"feed"
#define FacebookObjectConnectionTypeGroups  @"groups"
#define FacebookObjectConnectionTypePhotos  @"photos"
#define FacebookObjectConnectionTypeAlbums  @"albums"
#define FacebookObjectConnectionTypeStatuses  @"statuses"
#define FacebookObjectConnectionTypeLinks  @"links"
#define FacebookObjectConnectionTypeFriendLists @"friendlists"

typedef enum {
	FacebookObjectTypeStatus=0,    
	FacebookObjectTypePhoto=1,
    FacebookObjectTypeLink=2,
    FacebookObjectTypeVideo=3,
    FacebookObjectTypeCheckin=4,
    FacebookObjectTypeActivity=5,
    FacebookObjectTypeComment=6,
    FacebookObjectTypeUser=7,
    FacebookObjectTypePage=9,
    FacebookObjectTypeGroup=10,
    FacebookObjectTypeFriendlist=11,
    FacebookObjectTypeAlbum=12,
    FacebookObjectTypeMixed=25,
} FacebookObjectType;


extern NSString *const kFacebookPrivacyOnlyMe;
extern NSString *const kFacebookPrivacyPublic;
extern NSString *const kFacebookPrivacyFriends;
extern NSString *const kFacebookPrivacyCustom;


@interface NSString (FacebookObjectTypeParser)
- (FacebookObjectType)FacebookObjectTypeFromString; 
@end

// This is a straightforward mapping of all the possible objects returned by the Facebook API, graph and FQL
//  https://developers.facebook.com/docs/reference/api/

@interface FacebookObject : NSObject

+(FacebookObject*) facebookObjectWithID:(NSString*) objectID;

@property (nonatomic, copy) NSString *uuid;

@property (nonatomic) FacebookObjectType type;

// Every object in FB has a unique id
@property (nonatomic, copy) NSString *objectID;

// objects can have connections to other objects, which are also FacebookObjects
@property (nonatomic, copy) NSString *connectionType;

@property (nonatomic, weak, readonly) NSString *graphPath;

//e.g. a photo could use this to point to it's parent album
@property (nonatomic, strong) FacebookObject *parent;

// Facebook objects accessible from this object
@property (nonatomic, strong) NSArray *connections;

@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;

// Basic
@property (nonatomic, copy) NSString *toName;
@property (nonatomic, copy) NSString *toID;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *picture;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSData *imageBinary;
@property (nonatomic, copy) NSString *caption;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *description;
@property (nonatomic) BOOL installed;

// Linked objects
@property (nonatomic, copy) FacebookObject *from;
@property (nonatomic, copy) FacebookObject *album;


// Likes and comments
@property (nonatomic) BOOL cannotLike;
@property (nonatomic) BOOL wasLikedByCurrentUser;
@property (nonatomic, strong) NSNumber *likeCount;
@property (nonatomic) BOOL wasCommentedOnByCurrentUser;
@property (nonatomic) BOOL cannotComment;
@property (nonatomic, strong) NSNumber *commentCount;

//The fql used to create the object or associated with the connection
@property (nonatomic, copy) NSString *fql;

//Children properties
@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) NSArray *comments;
@property (nonatomic, strong) NSArray *likes;
@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSArray *photos;
@property (nonatomic, strong) NSArray *friendlists;
@property (nonatomic, strong) NSArray *pages;
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) NSArray *albums;

// Convenience
@property (nonatomic, strong) NSArray *closeFriends;
// Some links are to video, like YouTube links, and this property detects those
@property (nonatomic) BOOL isVideo;
@property (nonatomic, strong) NSString *additionalInfo;

// Debugging only
@property (nonatomic, strong) id originalObject;

// Common connections for convenience.
// These point to objects inside the connections array property
@property (nonatomic, weak, readonly) FacebookObject *homeConnection;
@property (nonatomic, weak, readonly) FacebookObject *feedConnection;
@property (nonatomic, weak, readonly) FacebookObject *groupsConnection;
@property (nonatomic, weak, readonly) FacebookObject *photosConnection;
@property (nonatomic, weak, readonly) FacebookObject *albumsConnection;
@property (nonatomic, weak, readonly) FacebookObject *linksConnection;
@property (nonatomic, weak, readonly) FacebookObject *statusesConnection;



@end
