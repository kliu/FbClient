//
//  Facebook.h
//  Swift
//
//  Created by John Wright on 11/13/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JokinglyOperation.h"
#import "FacebookObject.h"

typedef enum {
    FacebookLoadTypeNew=-1,
    FacebookLoadTypeInitial=0,
    FacebookLoadTypeOld=1
}FacebookLoadType;

typedef void(^FacebookObjectHandler)(FacebookObject *object);
typedef void(^FacebookConnectionHandler)(FacebookObject *updatedConnection, FacebookLoadType loadType, NSInteger numObjects);
typedef void(^FacebookLikesHandler)(NSString *objectId, NSArray *likes);

@interface FacebookClient : NSObject

// Facebook
extern NSString * const SwiftFBUserIsAuthenticated;
extern NSString * const SwiftFBErrorAuthenticating;
extern NSString * const SwiftFBRejectedAccessToken;
extern NSString * const SwiftFBConnectionError;
extern NSString * const SwiftFBAppID;
extern NSString * const SwiftFBCurrentUserID;
extern NSString * const SwiftFBAuthorizeURL;
extern NSString * const SwiftFBAuthorizeWithScopeURL;
extern NSString * const SwiftFBLoginURL;
extern NSString * const SwiftFBLoginSuccessURL;
extern NSString * const SwiftFBUIServerURL;
extern NSString * const SwiftFBAccessToken;
extern NSString * const SwiftFBExpiresIn;
extern NSString * const SwiftFBErrorReason;
extern NSString * const SwiftFBGraphApiGetURL;
extern NSString * const SwiftFBRestApiGetURL;
extern NSString * const SwiftFBGraphApiPostURL;
extern NSString * const SwiftFBStoreAccessToken;
extern NSString * const SwiftFBStoreTokenExpiry;
extern NSString * const SwiftFBStoreAccessPermissions;
extern NSString * const SwiftFBDateFormat;
extern NSString * const SwiftUserDismissedFBAuthenticationDialog;
extern NSString * const SwiftFBMultiQuery;

# pragma mark - Operation methods

+ (JokinglyOperation*) operationForURL:(NSString*) url;
+(void) queueOperationForURL:(NSString*)url notificationName:(NSString*) notificationName;
+(void) queueNoCacheOperationForURL:(NSString*)url handler:(JokinglyHandler) handler;
+ (JokinglyOperation *) photoOperationForURL:(NSString*) url;
+ (JokinglyOperation*) operationForURL:(NSString*) url;
+(void) queueOperationForURL:(NSString*)url handler:(JokinglyHandler) handler;
+(void) queueBatchOperationForURLs:(NSArray*)urls handler:(JokinglyHandler) handler;
+(void) queueOperationForComment:(NSString*)comment onObjectID:(NSString*) objectID handler:(JokinglyHandler) handler;
+(void) queueOperationForLikeOnObjectID:(NSString*) objectID isLiked:(BOOL) isLiked handler:(JokinglyHandler) handler;
+(void) queueOperationForPostStatus:(FacebookObject*)fob privacy:(NSDictionary*)privacy handler:(JokinglyHandler) handler;

#pragma mark Loaders
+(void) loadConnectionForObject:(FacebookObject*) object handler:(FacebookConnectionHandler) handler;
+(void) loadObjectWithId:(NSString*) objectID expectedType:(FacebookObjectType) type handler:(FacebookObjectHandler) handler;
+(void) loadAlbumForPhoto:(FacebookObject*) photo handler:(FacebookObjectHandler) handler;
+ (void) loadPicsOfFriends:(NSArray *)friends withPictureString:(NSString*) pictureString shouldDownloadIfInCache:(BOOL) shouldDownloadIfInCache;
+ (void) loadLikesForObjectId:(NSString*) objectId handler:(FacebookLikesHandler) handler;

#pragma Parsing Responses

+ (NSArray*) parseArrayResponseIntoFacebookObjects:(NSArray*) arrayResponse expectedType:(FacebookObjectType) expectedType;
+(NSArray*) parseNewsFeedResponseIntoFacebookObjects:(id) response expectedType:(FacebookObjectType) expectedType;
+(FacebookObject*) parseJSONDictIntoFacebookObject:(NSDictionary*) dict expectedType:(FacebookObjectType) expectedType;

# pragma mark - Properties
+ (NSOperationQueue *)operationQueue;
+ (NSString*) accessToken;
+ (NSDate*) accessTokenExpiration;
+ (NSString*) accessPermissions;
+ (void) setAccessToken:(NSString*) accessToken;
+ (void) setAccessTokenExpiration:(NSDate*) accessTokenExpiration;
+ (void) setAccessPermissions:(NSString*) accessPermissions;
+ (NSString*) currentUserID;
+ (void) setCurrentUserID:(NSString*) userID;
+(NSString*) jsonCachePath;
+(NSString*) photosCachePath;
+(void) flushCache;
+(NSString*) tempCacheDir;

#pragma mark - Connectionon loading
+ (void) loadUser:(FacebookObject*) user handler:(FacebookObjectHandler) handler;

#pragma mark URL Helpers
+ (NSString*)urlForRequest:(NSString*) request andParams:(NSDictionary*) params;
+(NSString*) newsFeedQueryForUser:(NSString*) userID limit:(NSInteger) limit;
+(NSString*) streamQueryForUser:(NSString*) userID andType:(FacebookObjectType) type limit:(NSInteger) limit updatedTime:(NSInteger) updatedTime;
+(NSString*) filterKeyForFacebookObjectType:(FacebookObjectType) type;
+ (NSString*) pictureURLForObjectID:(NSString*) objectID;


#pragma mark - Archiving

+(void) flushObjectWithId:(NSString*) objectId;



@end
