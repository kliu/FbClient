//
//  Facebook.h
//  Swift
//
//  Created by John Wright on 11/13/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FacebookObject.h"
#import "AFNetworking.h"

typedef enum {
    FacebookLoadTypeNew=-1,
    FacebookLoadTypeInitial=0,
    FacebookLoadTypeOld=1
}FacebookLoadType;

typedef void(^FacebookObjectHandler)(FacebookObject *object);
typedef void(^FacebookConnectionHandler)(FacebookObject *updatedConnection, FacebookLoadType loadType, NSInteger numObjects);
typedef void(^FacebookLikesHandler)(NSString *objectId, NSArray *likes);
typedef void(^FacebookJSONHandler)(id jsonObject);


#define kFacebookClientUserIsAuthenticated @"kFacebookClientIsAuthenticatedWithFB"
#define kFacebookClientErrorAuthenticating @"SwiftErrorAuthenticatingWithFB"
#define kFacebookClientRejectedAccessToken @"kFacebookClientRejectedAccessToken" 
#define kFacebookClientConnectionError @"kFacebookClientConnectionError"
#define kFacebookClientAppID @"192822854100507"
#define kFacebookClientAuthorizeURL @"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=%@&type=user_agent&display=popup"
#define kFacebookClientAuthorizeWithScopeURL @"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=%@&scope=%@&type=user_agent&display=popup"
#define kFacebookClientLoginURL @"https://www.facebook.com/login.php"
#define kFacebookClientLoginSuccessURL @"http://www.facebook.com/connect/login_success.html"
#define kFacebookClientUIServerURL @"http://www.facebook.com/connect/uiserver.php"
#define kFacebookClientAccessToken @"access_token="
#define kFacebookClientExpiresIn =  @"expires_in="
#define kFacebookClientErrorReason @"error_description="
#define kFacebookGraphURL @"https://graph.facebook.com"
#define kFacebookClientStoreAccessToken @"kFacebookClientAStoreAccessToken"
#define kFacebookClientCurrentUserID @"kFacebookClientCurrentUserID"
#define kFacebookClientStoreTokenExpiry @"kFacebookClientStoreTokenExpiry"
#define kFacebookClientStoreAccessPermissions @"kFacebookClientStoreAccessPermissions"
#define kFacebookClientDateFormat @"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZZ"
#define kFacebookClientUserDismissedFBAuthenticationDialog @"kFacebookClientDismissedFBAuthenticationDialog"
#define kFacebookClientMultiQuery @"kFacebookClientMultiQuery"
#define kFacebookObjectInitialCellLimit 10


@interface FacebookClient : AFHTTPClient


@property (nonatomic, readonly) NSMutableDictionary *defaultParams;


+ (FacebookClient *)sharedClient;

# pragma mark - Core methods
// You usually don't need to use thes
-(void) postComment:(NSString*)comment onObjectID:(NSString*) objectID handler:(FacebookJSONHandler) handler;
-(void) postLikeOnObjectId:(NSString*) objectID isLiked:(BOOL) isLiked handler:(FacebookJSONHandler) handler;
//-(void) postStatus:(FacebookObject*)fob privacy:(NSDictionary*)privacy handler:(FacebookObjectHandler) handler;

#pragma mark Loaders
-(void) loadConnectionForObject:(FacebookObject*) object handler:(FacebookConnectionHandler) handler;
-(void) loadObjectWithId:(NSString*) objectID expectedType:(FacebookObjectType) type handler:(FacebookObjectHandler) handler;
-(void) loadAlbumForPhoto:(FacebookObject*) photo handler:(FacebookObjectHandler) handler;
- (void) loadLikesForObjectId:(NSString*) objectId handler:(FacebookLikesHandler) handler;

#pragma Parsing Responses

- (NSArray*) parseArrayResponseIntoFacebookObjects:(NSArray*) arrayResponse expectedType:(FacebookObjectType) expectedType;
-(NSArray*) parseNewsFeedResponseIntoFacebookObjects:(id) response expectedType:(FacebookObjectType) expectedType;
-(FacebookObject*) parseJSONDictIntoFacebookObject:(NSDictionary*) dict expectedType:(FacebookObjectType) expectedType;

# pragma mark - Properties
- (NSOperationQueue *)operationQueue;
- (NSString*) accessToken;
- (NSDate*) accessTokenExpiration;
- (NSString*) accessPermissions;
- (void) setAccessToken:(NSString*) accessToken;
- (void) setAccessTokenExpiration:(NSDate*) accessTokenExpiration;
- (void) setAccessPermissions:(NSString*) accessPermissions;
- (NSString*) currentUserID;
- (void) setCurrentUserID:(NSString*) userID;
-(NSString*) jsonCachePath;
-(NSString*) photosCachePath;

#pragma mark - Connectionon loading
- (void) loadUser:(FacebookObject*) user handler:(FacebookObjectHandler) handler;

#pragma mark URL Helpers
-(NSString*) newsFeedQueryForUser:(NSString*) userID limit:(NSInteger) limit;
-(NSString*) streamQueryForUser:(NSString*) userID andType:(FacebookObjectType) type limit:(NSInteger) limit updatedTime:(NSInteger) updatedTime;
-(NSString*) filterKeyForFacebookObjectType:(FacebookObjectType) type;
- (NSString*) pictureURLForObjectID:(NSString*) objectID;


#pragma mark - Archiving

-(void) flushObjectWithId:(NSString*) objectId;



@end
