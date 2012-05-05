//
//  Facebook.m
//  Swift
//
//  Created by John Wright on 11/13/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "FacebookClient.h"
#import "JokinglyOperation.h"
#import "JSONKit.h"
#import "FMDatabase.h"

#define kAHSwiftInitialCellLimit 10

@interface NSString(FacebookClientAdditions) 

- (BOOL)containsString:(NSString *)string;
+ (NSString *)stringWithUUID;

@end

@implementation NSString(FacebookClientAdditions)

- (BOOL)containsString:(NSString *)string {
	return !NSEqualRanges([self rangeOfString:string], NSMakeRange(NSNotFound, 0));
}

+ (NSString *)stringWithUUID
{
    // create a new UUID which you own
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    
    // create a new CFStringRef (toll-free bridged to NSString)
    // that you own
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    
    // release the UUID
    CFRelease(uuid);
    
    // transfer ownership of the string
    // to the autorelease pool
    return uuidString;
}

@end

@interface FacebookClient()
+ (JokinglyHandler) checkForErrorHandler;
+ (JokinglyHandler) errorHandler;
+ (NSArray*) sortFriendsByName:(NSArray*) friends;
+(NSString*) userIdForURL:(NSString *) url;
+ (JokinglyJSONHandler) jsonHandler;

@end

@implementation FacebookClient


//Facebook

NSString * const FacebookClientUserIsAuthenticated = @"FacebookClientIsAuthenticatedWithFB";
NSString * const FacebookClientErrorAuthenticating = @"SwiftErrorAuthenticatingWithFB";
NSString * const FacebookClientRejectedAccessToken = @"FacebookClientRejectedAccessToken"; 
NSString * const FacebookClientConnectionError = @"FacebookClientConnectionError";
NSString * const FacebookClientAppID = @"192822854100507";
NSString * const FacebookClientAuthorizeURL = @"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=%@&type=user_agent&display=popup";
NSString * const FacebookClientAuthorizeWithScopeURL = @"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=%@&scope=%@&type=user_agent&display=popup";
NSString * const FacebookClientLoginURL = @"https://www.facebook.com/login.php";
NSString * const FacebookClientLoginSuccessURL = @"http://www.facebook.com/connect/login_success.html";
NSString * const FacebookClientUIServerURL = @"http://www.facebook.com/connect/uiserver.php";
NSString * const FacebookClientAccessToken = @"access_token=";
NSString * const FacebookClientExpiresIn =  @"expires_in=";
NSString * const FacebookClientErrorReason = @"error_description=";
NSString * const FacebookClientGraphApiURLWithToken =@"https://graph.facebook.com?access_token=%@";
NSString * const FacebookClientGraphApiGetURL =@"https://graph.facebook.com/%@";
NSString * const FacebookClientRestApiGetURL =@"https://api.facebook.com/method/%@";
NSString * const FacebookClientGraphApiPostURL = @"https://graph.facebook.com/%@";
NSString * const FacebookClientStoreAccessToken =@"FacebookClientAStoreAccessToken";
NSString * const FacebookClientCurrentUserID = @"FacebookClientCurrentUserID";
NSString * const FacebookClientStoreTokenExpiry = @"FacebookClientStoreTokenExpiry";
NSString * const FacebookClientStoreAccessPermissions = @"FacebookClientStoreAccessPermissions";
NSString * const FacebookClientDateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZZ";
NSString * const FacebookClientUserDismissedFBAuthenticationDialog = @"FacebookClientDismissedFBAuthenticationDialog";
NSString * const FacebookClientMultiQuery = @"FacebookClientMultiQuery";



#pragma mark - Operation creators


+(void) queueOperationForURL:(NSString*)url handler:(JokinglyHandler) handler{
    JokinglyOperation *operation = [self operationForURL:url];
    [operation addSuccessHandler:handler];
    [[self operationQueue] addOperation:operation];
}

+(void) queueNoCacheOperationForURL:(NSString*)url handler:(JokinglyHandler) handler{
    JokinglyOperation *operation = [self operationForURL:url];
    operation.shouldCheckCache = NO;
    operation.shouldStoreInCache = NO;
    [operation addSuccessHandler:handler];
    [[self operationQueue] addOperation:operation];
}

// See: https://developers.facebook.com/docs/reference/api/batch/
+(void) queueBatchOperationForURLs:(NSArray*)urls handler:(JokinglyHandler) handler{
    
    NSMutableArray *batchArray = [NSMutableArray arrayWithCapacity:[urls count]];
    for (NSString *url in urls) {
        [batchArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"GET", @"method", url, @"relative_url", nil]];
    }
    NSString *body = [NSString stringWithFormat:@"batch=%@", [batchArray JSONString]];
    
    JokinglyOperation *operation = [JokinglyOperation postOperationWithURL:[NSString stringWithFormat:FacebookClientGraphApiURLWithToken, [self accessToken]] andBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    operation.shouldCheckCache = NO;
    operation.shouldStoreInCache = NO;
    [operation addSuccessHandler:handler];
    [[self operationQueue] addOperation:operation];
}



+(void) queueOperationForURL:(NSString*)url notificationName:(NSString*) notificationName {
    JokinglyOperation *operation = [self operationForURL:url];
    operation.notificationName = notificationName;
    [[self operationQueue] addOperation:operation];
}

+ (JokinglyOperation*) operationForURL:(NSString*) url {
    JokinglyOperation *operation = [JokinglyOperation operationWithURL:[self urlForRequest:url andParams:nil]];
    
    
    operation.cacheDirectoryPathJSON = [self jsonCachePath];
    operation.cacheDirectoryPathPhotos = [self photosCachePath];
    operation.jsonHandler = [self jsonHandler];
    operation.checkForAppErrorHandler = [self checkForErrorHandler];
    [operation addErrorHandler:[self errorHandler]];
    operation.url = url;
    return operation;
}

+ (JokinglyOperation *) photoOperationForURL:(NSString*) url {
    if (!url) {
        NSLog(@"!!Warning, attempting to load image that doesn't exist!!!!!");
        return nil;
    }
    JokinglyOperation *operation = [JokinglyOperation operationWithURL:url];
    operation.cacheDirectoryPathPhotos = [self photosCachePath];
    operation.requestType = JokinglyPhotoRequest;
    operation.url = url;
    operation.shouldCheckCache = YES;
    operation.shouldStoreInCache = YES;
    operation.checkForAppErrorHandler = [self checkForErrorHandler];
    [operation addErrorHandler:[self errorHandler]];
    // TODO: this is good for all but profile pics which need to flushed from cache a few times per minute
    operation.shouldDownloadIfInCache = NO;
    return operation;
}

+(void) queueOperationForComment:(NSString*)comment onObjectID:(NSString*) objectID handler:(JokinglyHandler) handler {
    NSString *commentURL = [NSString stringWithFormat:@"%@/comments", objectID];
    NSString *body = [NSString stringWithFormat:@"message=%@", comment];
    JokinglyOperation *operation = [JokinglyOperation postOperationWithURL:[self urlForRequest:commentURL andParams:nil] andBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    operation.checkForAppErrorHandler = [self checkForErrorHandler];
    [operation addErrorHandler:[self errorHandler]];
    [operation addSuccessHandler:handler];
    [[self operationQueue] addOperation:operation];
} 

+(void) queueOperationForLikeOnObjectID:(NSString*) objectID isLiked:(BOOL) isLiked handler:(JokinglyHandler) handler
{
    if (!objectID || [objectID containsString:@"null"]) {
        NSAssert(false, @"Cannot pass null objectID");
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/likes", objectID];
    JokinglyOperation *operation;
    if (isLiked) {
        operation = [JokinglyOperation postOperationWithURL:[self urlForRequest:url andParams:nil] andBody:nil];    
    } else {
        operation = [JokinglyOperation deleteOperationWithURL:[self urlForRequest:url andParams:nil]]; 
    }
    [operation addSuccessHandler:handler];
    operation.checkForAppErrorHandler = [self checkForErrorHandler];
    [operation addErrorHandler:[self errorHandler]];
    [[self operationQueue] addOperation:operation];
}

+(NSString*)privacyObject:(NSDictionary*)privacy
{
    NSString *strJson=nil;
    if( [privacy count] >0 )
        strJson = [privacy JSONString];
    
    return strJson;
}
+(NSData*)bodyForPostStatus:(FacebookObject*)obj privacy:(NSDictionary*)privacy
{
    NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:5];
    NSData *bodyData=nil;
    obj.type = FacebookObjectTypeStatus;
    
    // Priority : Image --> Link --> Text status
    if ( obj.imageBinary && ([obj.imageBinary isKindOfClass:[NSData class]] || [obj.imageBinary isKindOfClass:[NSString class]]) )
    {
        obj.type = FacebookObjectTypePhoto;
        [dict setObject:obj.imageBinary forKey:@"image"];
        if( obj.message )
            [dict setObject:obj.message forKey:@"message"];
        else if( obj.name )
            [dict setObject:obj.name forKey:@"message"];
        else if( obj.caption )
            [dict setObject:obj.caption forKey:@"message"];
    }
    else if( obj.link!=nil)
    {
        obj.type = FacebookObjectTypeLink;
        [dict setObject:obj.link forKey:@"link"];
        if( obj.message )
            [dict setObject:obj.message forKey:@"message"];
        if( obj.name )
            [dict setObject:obj.name forKey:@"name"];
        if( obj.caption )
            [dict setObject:obj.caption forKey:@"caption"];
        /* // TODO; description conflicts with NSObject
         if( obj.description )
         [dict setObject:obj.description forKey:@"description"];
         */
    }
    else if( 0 /* TODO: Video */ )
    {
        obj.type = FacebookObjectTypeVideo;
        
    }
    else
    {
        obj.type = FacebookObjectTypeStatus;
        [dict setObject:@"status" forKey:@"type"];
        if( obj.message )
            [dict setObject:obj.message forKey:@"message"];
        if( obj.name )
            [dict setObject:obj.name forKey:@"name"];
    }
    NSString *privacyObj = [self privacyObject:privacy];
    if( privacyObj && [obj.toID length]==0 )    // don't apply privacy settings if we have a destination
        [dict setObject:privacyObj forKey:@"privacy"];
    
    
    if( [dict count] >0 )
        bodyData = [self generatePostBody:dict];
    return bodyData;
}
+(NSString*)urlForPostFacebookObject:(FacebookObject*)fob
{
    FacebookObjectType type = fob.type;
    NSString *url=fob.toID==nil?@"me/feed":[NSString stringWithFormat:@"%@/feed", fob.toID];
    if( type == FacebookObjectTypePhoto )
    {
        url=fob.toID==nil?@"me/photos":[NSString stringWithFormat:@"%@/photos", fob.toID];
    }
    else 
    {
        
    }
    return url;
}
+(void) queueOperationForPostStatus:(FacebookObject*)fob privacy:(NSDictionary *)privacy  handler:(JokinglyHandler) handler;
{
    NSData *dataBody = [self bodyForPostStatus:fob privacy:privacy];
    
    NSString *postURL = [self urlForPostFacebookObject:fob];
    
    
    JokinglyOperation *operation = [JokinglyOperation multiPartPostOperationWithURL:[self urlForRequest:postURL andParams:nil] andBody:dataBody];
    operation.checkForAppErrorHandler = [self checkForErrorHandler];
    [operation addErrorHandler:[self errorHandler]];
    [operation addSuccessHandler:handler];
    [[self operationQueue] addOperation:operation];
}


#pragma mark - Loaders



+(void) loadConnectionForObject:(FacebookObject*) object handler:(FacebookConnectionHandler) handler {
    if (!object || !object.graphPath) {
        return;
    }
    
    FacebookObject *archivedObject = [self readObjectWithKey:object.graphPath];
    if (archivedObject) {
        handler(archivedObject, FacebookLoadTypeInitial, archivedObject.data.count);
    } else {
        archivedObject = object;
    }
    
    if (archivedObject && archivedObject.updatedAt) {
        NSDate *updatedAt = archivedObject.updatedAt;
        NSTimeInterval timeSinceNow = [[NSDate date] timeIntervalSinceDate:updatedAt];
        if (timeSinceNow < 200) {
            // No need to refresh
            return;
        }
    }
    
    if (!archivedObject.data) {
        archivedObject.data = [NSArray array];
    }
    
    
    NSString *query = object.graphPath;
    if (archivedObject.updatedAt) {
        NSTimeInterval updatedTime = [archivedObject.updatedAt timeIntervalSince1970];
        if (object.fql) {
            query = [self streamQueryForUser:object.objectID andType:object.type limit:100 updatedTime:updatedTime];
        } else {
            query = [NSString stringWithFormat:@"%@?since=%.0f&date_format=U", query, updatedTime];            
        }
    }
    
    [FacebookClient queueNoCacheOperationForURL:query handler:^(JokinglyOperation *operation) {
        if (operation.isSuccessful) {
            NSArray *parsedObj = operation.result;
            NSArray *parsedResults;
            if (object.fql) {
                parsedResults = [FacebookClient parseNewsFeedResponseIntoFacebookObjects:parsedObj expectedType:object.type];
            } else parsedResults = [FacebookClient parseArrayResponseIntoFacebookObjects:parsedObj expectedType:object.type];
            if (parsedResults && parsedResults.count > 0) {
                // Prepend the results to the existing array
                NSMutableArray *newData = [NSMutableArray arrayWithArray:parsedResults];
                [newData addObjectsFromArray:archivedObject.data];
                FacebookLoadType loadType = archivedObject.data.count ? FacebookLoadTypeNew : FacebookLoadTypeInitial;
                // Prune the results from growing too large
                if (newData.count > 300) {
                    archivedObject.data = [newData objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 200)]];
                } else {
                    archivedObject.data = newData;                    
                }
                [self saveObject:archivedObject withKey:object.graphPath];
                handler(archivedObject, loadType, parsedResults.count);
            }
        }
    }];
    
}

+(void) loadObjectWithId:(NSString*) objectID expectedType:(FacebookObjectType) type handler:(FacebookObjectHandler) handler {
    if (objectID) {
        JokinglyOperation *operation = [self operationForURL:objectID];
        operation.shouldCheckCache = YES;
        operation.shouldStoreInCache = YES;
        [operation addSuccessHandler:^(JokinglyOperation *operation) {
            if (operation.result) {
                FacebookObject *object = [self parseJSONDictIntoFacebookObject:operation.result expectedType:type];
                handler(object);
            }
        }];
        [[self operationQueue] addOperation:operation];
    }
}

// Populates out the object with all the information about it

+ (void) loadUser:(FacebookObject*) user handler:(FacebookObjectHandler) handler {
    
    BOOL isCurrentUserRequest = [user.objectID isEqualToString:@"me"];
    //Make sure we use the actual current userid
    user.objectID = (isCurrentUserRequest && [self currentUserID]) ? [self currentUserID] : user.objectID;
    
    // Make sure the connections are uptodate on this user
    user.connections = [self connectionsForObject:user];
    
    // Try to load this object from the archive
    FacebookObject *object = [self readObjectWithKey:user.graphPath];
    if (object) {
        handler(object);
        
        // Check the archive date and see if we perhaps don't need to refresh this object
        if (object.updatedAt) {
            NSDate *updatedAt = object.updatedAt;
            NSTimeInterval timeSinceNow = [[NSDate date] timeIntervalSinceDate:updatedAt];
            if (timeSinceNow < 50) {
                // No need to refresh
                return;
            }
        }
    }

    // The basic connections for normal users and pages
    NSMutableArray *urls = [NSMutableArray arrayWithObjects:user.objectID, [NSString stringWithFormat:@"%@/albums?limit=5000",  user.objectID],  [NSString stringWithFormat:@"%@/likes?limit=100", user.objectID], [NSString stringWithFormat:@"%@/groups", user.objectID],  nil];
    
    // connections that only should be loaded for the currrent user
    if ([user.objectID isEqualToString:[self currentUserID]] || [user.objectID isEqualToString:@"me"]) {
        [urls addObject:[NSString stringWithFormat:@"%@/friends?limit=5000", user.objectID]];
        [urls addObject:[NSString stringWithFormat:@"%@/friendlists", user.objectID]];
    }
    
    [self queueBatchOperationForURLs:urls handler:^(JokinglyOperation *operation) {
        NSArray *jsonResult = operation.result;
        if (jsonResult && [jsonResult isKindOfClass:[NSArray class]]) {
            
            NSDictionary *profileInfo = [[[jsonResult objectAtIndex:0] valueForKey:@"body"] objectFromJSONString];
            FacebookObject *objectToLoad = [FacebookClient parseJSONDictIntoFacebookObject:profileInfo expectedType:object.type];
            objectToLoad.originalObject = jsonResult;
            objectToLoad.uuid = object.uuid;
            
            NSDictionary *albumsJSON = [[[jsonResult objectAtIndex:1] valueForKey:@"body"] objectFromJSONString];
            NSArray *albums = [albumsJSON valueForKey:@"data"];
            objectToLoad.albums = [FacebookClient parseArrayResponseIntoFacebookObjects:albums expectedType:FacebookObjectTypeAlbum];
            
            NSDictionary *likesJSON = [[[jsonResult objectAtIndex:2] valueForKey:@"body"] objectFromJSONString];
            NSArray *likes = [likesJSON valueForKey:@"data"];
            objectToLoad.likes = [FacebookClient parseArrayResponseIntoFacebookObjects:likes  expectedType:FacebookObjectTypePage];
            
            
            NSDictionary *groupsJSON = [[[jsonResult objectAtIndex:3] valueForKey:@"body"] objectFromJSONString];
            NSArray *groups = [groupsJSON valueForKey:@"data"];
            objectToLoad.groups = [FacebookClient parseArrayResponseIntoFacebookObjects:groups expectedType:FacebookObjectTypeGroup];
            
            // connections that only should be loaded for the currrent user
            if ([objectToLoad.objectID isEqualToString:[self currentUserID]] || [objectToLoad.objectID isEqualToString:@"me"]) {
                // A complete list of a user's friend can only be retrieved for the current user according to:
                // http://stackoverflow.com/questions/3818588/getting-friends-of-friends-in-fb-graph-api
                NSDictionary *friendsJSON = [[[jsonResult objectAtIndex:4] valueForKey:@"body"] objectFromJSONString];
                NSArray *friends = [friendsJSON valueForKey:@"data"];
                objectToLoad.friends = [FacebookClient parseArrayResponseIntoFacebookObjects:friends expectedType:FacebookObjectTypeUser];
                
                NSDictionary *friendlistsJSON = [[[jsonResult objectAtIndex:5] valueForKey:@"body"] objectFromJSONString];
                NSArray *friendlists = [friendlistsJSON valueForKey:@"data"];
                objectToLoad.friendlists = [FacebookClient parseArrayResponseIntoFacebookObjects:friendlists expectedType:FacebookObjectTypeGroup];
                
                 
            }
            objectToLoad.connections = [self connectionsForObject:objectToLoad];
            [self saveObject:objectToLoad withKey:objectToLoad.graphPath];
            if (isCurrentUserRequest) {
                [self setCurrentUserID:objectToLoad.objectID];
            }
            handler(objectToLoad);
        }
    }];
    
}

+(void) loadAlbumForPhoto:(FacebookObject*) photo handler:(FacebookObjectHandler) handler {
    if (photo.album && photo.album.name) {
        handler(photo.album);
    }
    //TODO: check the albums connection for the album name
    if (photo.album && photo.album.objectID) {
        [self loadObjectWithId:photo.album.objectID expectedType:FacebookObjectTypeAlbum handler:handler];    
    }
}


// Can be used to download a bunch of pics in advance of a group of friends to make scrolling faster
+ (void) loadPicsOfFriends:(NSArray *)friends withPictureString:(NSString*) pictureString shouldDownloadIfInCache:(BOOL) shouldDownloadIfInCache {
    
    if (!(friends && [friends count])) return;
    
    //Create download operations for these friends pics
    for (NSDictionary *friend in friends) {
        NSString *pictureURL = [NSString stringWithFormat:[pictureString copy], [friend valueForKey:@"id"]];
        JokinglyOperation *operation = [self photoOperationForURL:pictureURL];
        operation.shouldDownloadIfInCache = shouldDownloadIfInCache;
        [[self operationQueue] addOperation:operation];
    }
}

+ (void) loadLikesForObjectId:(NSString*) objectId handler:(FacebookLikesHandler) handler {
    if (objectId) {
        NSString *likesURL = [NSString stringWithFormat:@"%@/likes", objectId];
        JokinglyOperation *operation = [self operationForURL:likesURL];
        operation.shouldCheckCache = YES;
        operation.shouldStoreInCache = YES;
        [operation addSuccessHandler:^(JokinglyOperation *operation) {
            if (operation.result && [operation.result isKindOfClass:[NSArray class]]) {
                handler(objectId, operation.result);
            }
        }];
        [[self operationQueue] addOperation:operation];
    }
}


#pragma mark -
#pragma mark Parse Methods


//https://www.facebook.com/logout.php?next=YOUR_URL&access_token=ACCESS_TOKEN

+(NSString*) idInDict:(NSDictionary*) dict {
    NSString *objectID;
    if ([dict valueForKey:@"object_id"]) {
        objectID = [dict valueForKey:@"object_id"];
        if ([objectID isKindOfClass:[NSNull class]]) {
            objectID = nil;
        }
    }
    if (!objectID) {
        objectID = [dict valueForKey:@"id"];
    }
    
    if (!objectID) {
        objectID = [dict valueForKey:@"post_id"];
    }
    
    if ([objectID isKindOfClass:[NSNumber class]]) {
        objectID = [(NSNumber*)objectID stringValue];
    }
    
    if (!objectID || [objectID containsString:@"null"]) {
        NSAssert(false, @"No objectID detected by Facebook Client");
    }
    return objectID;
}

+ (NSString*) valueToString:(id) value {
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    if ([value containsString:@"null"]) {
        NSAssert(false, @"need to catch FQL nulls");
    }
    return [value description];
}


+ (NSString*) pictureURLForObjectID:(NSString*) objectID {
    if (!objectID) {
        return nil;
    }
    NSString *objectIDString = [self valueToString:objectID];
    
    if ([objectIDString containsString:@"null"] || [objectIDString containsString:@"_"]) {
        NSAssert(false, @"need to catch FQL nulls");
    }
    
    NSString *accessToken = [FacebookClient accessToken];
    NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", objectIDString];
    url = [url stringByAppendingFormat:@"?access_token=%@", accessToken];
    return url;
}

+(FacebookObjectType) typeFromDict:(NSDictionary*) dict {
    id typeObject = [dict valueForKey:@"type"];
    if ([typeObject isKindOfClass:[NSString class]]) {
        return  [typeObject FacebookObjectTypeFromString];
    }
    if ([typeObject isKindOfClass:[NSNumber class]]) {
        int type = [typeObject intValue];
        switch (type) {
            case 247:
                return FacebookObjectTypePhoto;
                break;
            case 46:
            case 237:
                return FacebookObjectTypeStatus;
                break;
            case 80:
                return FacebookObjectTypeLink;
                break;
            case 128:
                return FacebookObjectTypeVideo;
                break;
            default:
                break;
        }
    }
    
    if ([dict valueForKey:@"height"]) return FacebookObjectTypePhoto;
    
    return FacebookObjectTypeMixed;
}

+(void) setTimestampsFromDict:(NSDictionary*) dict onObject:(FacebookObject*) object {
    NSString *createdTimeString = [dict valueForKey:@"created_time"];
    if (createdTimeString) {
        object.createdAt = [NSDate dateWithTimeIntervalSince1970:[createdTimeString doubleValue]];
    }
    NSString *updatedTimeString = [dict valueForKey:@"updated_time"];
    if (updatedTimeString) {
        object.updatedAt = [NSDate dateWithTimeIntervalSince1970:[updatedTimeString doubleValue]];
    }
}

//Extract the album id from the link using logic found http://stackoverflow.com/a/7236370/32829
+(NSString*) extractAlbumIdFromLink:(NSString*) link {
    if (link && link.length > 20) {
        NSInteger firstPos = [link rangeOfString:@"set=a."].location + 6;
        if (firstPos <= 0) {
            firstPos = [link rangeOfString:@"set=p."].location + 6;
        }
        if (firstPos <= 0) {
            firstPos = [link rangeOfString:@"set=at."].location + 7;
        }
        if (firstPos >0 ) {
            NSArray *restOfString = [[link substringFromIndex:firstPos] componentsSeparatedByString:@"."];
            if (!restOfString || !restOfString.count) {
                restOfString = [[link substringFromIndex:firstPos] componentsSeparatedByString:@"&"];
            }
            if (restOfString && restOfString.count) {
                return [restOfString objectAtIndex:0];
            }
        } else {
            NSLog(@"%@", link);
        }
    }
    return nil;
}

+ (void) setVideoFromDict:(NSDictionary*) dict onObject:(FacebookObject*) object {
    if (object.type != FacebookObjectTypeVideo) {
        return;
    }
    if ([dict valueForKey:@"source"] ) {
        //Youtube link to the whole video goes here
        object.source = [dict valueForKey:@"source"];
    }
}

+(void) setAlbumIDFromDict:(NSDictionary*)dict onObject:(FacebookObject*) object {
    
    if (!object.album) {
        object.album = [[FacebookObject alloc] init];
    }
    
    object.album.objectID = [self extractAlbumIdFromLink:[dict valueForKey:@"link"]];
    
    // Look for an attachment in a news feed object
    if (!object.album.objectID) {
        NSDictionary *attachment = [dict valueForKey:@"attachment"];
        if (attachment) {
            NSArray *media = [attachment valueForKey:@"media"];
            if (media && media.count) {
                NSString *href = [[media objectAtIndex:0] valueForKey:@"href"];
                object.album.objectID = [self extractAlbumIdFromLink:href];
            }
        }
    }                        
}

+(void) setPictureFromDict:(NSDictionary*) dict onObject:(FacebookObject*) object {
    
    FacebookObjectType type = object.type;//[self typeFromDict:dict];
    
    NSString *objectID = [self idInDict:dict];
    if (type == FacebookObjectTypePhoto || type == FacebookObjectTypeVideo) {
        if (objectID && type == FacebookObjectTypePhoto && ![objectID containsString:@"_"]) {
            if ([dict valueForKey:@"source"]) {
                object.picture = [dict valueForKey:@"source"];
            }
            
            if (!object.picture) {
                object.picture = [self pictureURLForObjectID:objectID];
            }
        }   
        
        if (!object.picture && [dict valueForKey:@"picture"] && type == FacebookObjectTypeVideo) {
            object.picture = [dict valueForKey:@"picture"];
        }
        
        
        NSDictionary *attachment = [dict valueForKey:@"attachment"];
        if (!object.picture && attachment) {
            if (type == FacebookObjectTypeVideo) {
                NSString *fbid = [self valueToString:[attachment valueForKey:@"fb_object_id"]];
                if (fbid) {
                    object.picture = [self pictureURLForObjectID:fbid];
                } 
                
            }
            NSArray *media = [attachment valueForKey:@"media"];
            if (!object.picture && media && [media count]) {
                NSDictionary *photo = [[media objectAtIndex:0]  valueForKey:@"photo"];
                object.picture = [photo valueForKey:@"src"];
                if (!object.picture) {
                    NSString *fbid = [self valueToString:[photo valueForKey:@"fbid"]];
                    if (fbid) {
                        object.picture = [self pictureURLForObjectID:fbid];
                    } 
                }
            }
        }
    }
    
    if (!object.picture && type == FacebookObjectTypeLink) {
        NSDictionary *attachment = [dict valueForKey:@"attachment"];
        if (attachment) {
            NSArray *media = [attachment valueForKey:@"media"];
            if (media && [media count]) {
                object.picture = [[media objectAtIndex:0]  valueForKey:@"src"];
            } 
        }
    }
    
    if (!object.picture && [dict valueForKey:@"picture"]) {
        object.picture = [dict valueForKey:@"picture"];
    }
    
    if (!object.picture && objectID && ![objectID containsString:@"_"]) {
        object.picture = [FacebookClient pictureURLForObjectID:objectID];
    }
    
    if (object.picture && [object.picture isKindOfClass:[NSArray class]]) {
        NSArray *pictures = (NSArray*) object.picture;
        if ([pictures count]) object.picture = [pictures objectAtIndex:0];
    }
    
    
    if ([object.picture hasSuffix:@"_s.jpg"]) {
        // We don't use small pictures in this app.
        NSArray *components = [object.picture componentsSeparatedByString:@"_s.jpg"];
        NSString *normalPicture = [NSString stringWithFormat:@"%@_n.jpg", [components objectAtIndex:0]]; 
        object.picture = normalPicture;
    }
    
}


+(void) setCommentsFromDict:(NSDictionary*) dict onFacebookObject:(FacebookObject*) object {
    
    // Sometimes, such as in the multi-query case, the comments are directly off the main object
    NSArray *comments = [dict valueForKey:@"comments"];
    
    if (comments && [comments isKindOfClass:[NSDictionary class]]) {
        NSDictionary *commentsDict = (NSDictionary*)comments;
        // the graph api returns comments in a data array
        object.wasCommentedOnByCurrentUser = [[comments valueForKey:@"user_commented"] boolValue];
        
        comments = [commentsDict valueForKey:@"data"];
        if (!comments) {
            // this is the fql case
            comments = [commentsDict valueForKey:@"comment_list"];            
        }       
    }
    
    NSString *currentUserID = [self currentUserID];
    if (comments && [comments count]) {
        NSMutableArray *commentObjects = [NSMutableArray arrayWithCapacity:[comments count]];
        for (NSDictionary *commentDict in comments) {
            FacebookObject *commentObject = [self parseJSONDictIntoFacebookObject:commentDict expectedType:FacebookObjectTypeComment];
            if (!commentObject.from) {
                commentObject.from = [[FacebookObject alloc] init];
            }
            
            if ([commentDict valueForKey:@"fromid"]) {
                commentObject.from.objectID = [commentDict valueForKey:@"fromid"];
                if ([commentObject.from.objectID isKindOfClass:[NSNumber class]]) {
                    commentObject.from.objectID = [(NSNumber*)commentObject.from.objectID stringValue];
                }
            }
            
            if ([commentDict valueForKey:@"name"]) {
                commentObject.from.name = [commentDict valueForKey:@"name"];                
            }
            
            if (!commentObject.from.picture && commentObject.from.objectID) {
                commentObject.from.picture = [self pictureURLForObjectID:commentObject.from.objectID];
            }
            
            
            if ([commentDict valueForKey:@"can_like"]) {
                commentObject.cannotLike = ![[commentDict valueForKey:@"can_like"] boolValue];
            }
            if ([commentDict valueForKey:@"likes"]) {
                commentObject.likeCount = [commentDict valueForKey:@"likes"];
            }
            commentObject.wasLikedByCurrentUser = [[commentDict valueForKey:@"user_likes"] boolValue];
            
            if (commentObject.from && [commentObject.from.objectID isEqualToString:currentUserID]) {
                object.wasCommentedOnByCurrentUser = YES;
                commentObject.wasCommentedOnByCurrentUser = YES;
            }
            [commentObjects addObject:commentObject];
        }
        object.comments = commentObjects;
    }
}

+(void) setLikesFromDict:(NSDictionary*) dict onFacebookObject:(FacebookObject*) object {
    
    // Sometimes, such as in the multi-query case, the comments are directly off the main object
    NSArray *likes = [dict valueForKey:@"likes"];
    
    if (likes && [likes isKindOfClass:[NSDictionary class]]) {
        object.wasLikedByCurrentUser = [[likes valueForKey:@"user_likes"] boolValue];
        object.likeCount =  [likes valueForKey:@"count"];
        if ([likes valueForKey:@"can_like"]) {
            object.cannotLike  = ![[likes valueForKey:@"can_like"] boolValue];
        }
        
        NSDictionary *likesDict = (NSDictionary*)likes;
        // the graph api returns likes in a data array
        likes = [likesDict valueForKey:@"data"];
        if (!likes) {
            // this is the fql case
            likes = [likesDict valueForKey:@"likes_list"];            
        }       
    }
    if (likes && [likes isKindOfClass:[NSNumber class]]) {
        object.likeCount = (NSNumber*) likes;
    }
    
    if (likes && [likes isKindOfClass:[NSArray class]] && [likes count]) {
        NSMutableArray *likeObjects = [NSMutableArray arrayWithCapacity:[likes count]];
        for (NSDictionary *like in likes) {
            FacebookObject *likeObject = [self parseJSONDictIntoFacebookObject:like expectedType:FacebookObjectTypeComment];
            likeObject.cannotLike = ![[like valueForKey:@"can_like"] boolValue];
            likeObject.likeCount = [like valueForKey:@"likes"];
            likeObject.wasLikedByCurrentUser = [[like valueForKey:@"user_likes"] boolValue];
            if ([likeObject.from.objectID isEqualToString:[self currentUserID]]) {
                object.wasLikedByCurrentUser = YES;
            }
            [likeObjects addObject:likeObject];
        }
        object.likes = likeObjects;
    }
}


+(void) setLinkFromResponse:(NSDictionary*) dict onFacebookObject:(FacebookObject*) object {
    NSDictionary *attachment = [dict valueForKey:@"attachment"];
    if (attachment) {
        object.link = [attachment valueForKey:@"href"];
        object.caption = [attachment valueForKey:@"caption"];
        object.description = [attachment valueForKey:@"description"];
        object.name = [attachment valueForKey:@"name"];
    }
    if (!object.link) {
        object.link = [dict valueForKey:@"link"];
        object.caption = [dict valueForKey:@"caption"];
        object.description = [dict valueForKey:@"description"];
        object.name = [dict valueForKey:@"name"];
    }
}

+(NSArray*) parseNewsFeedResponseIntoFacebookObjects:(id) response expectedType:(FacebookObjectType) expectedType  {
    
    if ([response isKindOfClass:[NSDictionary class]] && [response valueForKey:@"error_code"]) {
        //Check for an error
        //TODO make sure errors are handled somewhere;
        NSLog(@"Error parsing response %@", response);
        return nil;
    }
    
    // 2 query results
    // First is posts from stream table and the second are users for those posts 
    if (response && [response isKindOfClass:[NSArray class]]) {
        
        NSArray *posts = [response filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name == %@)",@"streamQuery"]];
        if (posts && [posts count]) {
            posts = [[posts objectAtIndex:0] valueForKey:@"fql_result_set"];
        }
        NSArray *users = [response filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name == %@)",@"profileQuery"]]; 
        if (users && [users count]) {
            users = [[users objectAtIndex:0] valueForKey:@"fql_result_set"];
        }
        NSArray *comments = [response filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name == %@)",@"commentsQuery"]]; 
        if (comments && [comments count]) {
            comments = [[comments objectAtIndex:0] valueForKey:@"fql_result_set"];
        }
        
        NSMutableArray *newPosts = [NSMutableArray arrayWithCapacity:[posts count]];
        NSInteger index = 0;
        for (NSDictionary *post in posts) {
            NSMutableDictionary *mutablePost = [post mutableCopy];
            NSString *actorId = [post valueForKey:@"actor_id"];
            if (users && [users count]) {
                NSArray *filtered = [users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(id == %@)", actorId]];
                if (filtered && [filtered count]) {
                    NSDictionary *user = [filtered objectAtIndex:0];
                    [mutablePost setObject:user forKey:@"from"];
                }
            }
            
            //Go find all the comments for this post
            if (comments && [comments count]) {
                NSString *postID = [post valueForKey:@"post_id"];
                NSArray *filteredComments = [comments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(post_id == %@)", postID]];
                // Go through the comments and find their names in the user table
                NSMutableArray *newComments = [NSMutableArray array];
                for (NSDictionary *comment in filteredComments) {
                    NSMutableDictionary *mutableComment = [comment mutableCopy];
                    NSString *fromObjectID = [comment valueForKey:@"fromid"];
                    NSArray *filtered = [users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(id == %@)", fromObjectID]];
                    if (filtered && [filtered count]) {
                        NSDictionary *user = [filtered objectAtIndex:0];
                        [mutableComment setValue:[user valueForKey:@"name"] forKey:@"name"];
                    }
                    [newComments addObject:mutableComment];
                }
                [mutablePost setValue:newComments forKey:@"comments"];
            }
            [newPosts addObject:mutablePost];
            index +=1;
        }
        return [self parseArrayResponseIntoFacebookObjects:newPosts expectedType:expectedType];   
    }
    return nil;
    
}

+ (NSArray*) parseArrayResponseIntoFacebookObjects:(NSArray*) arrayResponse expectedType:(FacebookObjectType) expectedType  {
    
    if ([arrayResponse isKindOfClass:[NSDictionary class]] && [arrayResponse valueForKey:@"error_code"]) {
        //Check for an error
        //TODO make sure errors are handled somewhere;
        NSLog(@"Error parsing response %@", arrayResponse);
        return nil;
    }
    
    
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[arrayResponse count]];
    for (NSDictionary *dict in arrayResponse) {
        [objects addObject:[self parseJSONDictIntoFacebookObject:dict expectedType:expectedType]];
    }
    return objects;
    
}

+(FacebookObject*) parseJSONDictIntoFacebookObject:(NSDictionary*) dict expectedType:(FacebookObjectType) expectedType {
    FacebookObject *object = [[FacebookObject alloc] init];
    if (expectedType != FacebookObjectTypeMixed) {
        object.type = expectedType;
    } else {
        object.type = [self typeFromDict:dict];            
    }
    
    NSDictionary *from = [dict valueForKey:@"from"];
    if (from) {
        object.from = [self parseJSONDictIntoFacebookObject:from expectedType:FacebookObjectTypeUser];
    }
    object.objectID = [self idInDict:dict];
    [self setPictureFromDict:dict onObject:object];
    [self setTimestampsFromDict:dict onObject:object];
    if (object.type == FacebookObjectTypeLink) {
        [self setLinkFromResponse:dict onFacebookObject:object];
    }
    if (!object.name) {
        object.name = [dict valueForKey:@"name"];
    }
    if (!object.caption) {
        object.caption = [dict valueForKey:@"caption"];
    }        
    if (!object.description) {
        object.description = [dict valueForKey:@"description"];
    }
    if (!object.name) {
        object.name = [dict valueForKey:@"name"];
    }
    if (!object.message) {
        object.message = [dict valueForKey:@"message"];
    }
    if (!object.message) {
        object.message = [dict valueForKey:@"text"];
    }
    if (!object.picture) {
        object.picture = [dict valueForKey:@"picture"];
    }
    
    if( [dict objectForKey:@"installed"] )
        object.installed = [[dict objectForKey:@"installed"] boolValue];
    
    if (object.type == FacebookObjectTypePhoto) {
        [self setAlbumIDFromDict:dict onObject:object];
    }
    
    //Let's check out work 
    if (object.picture && ![object.picture isKindOfClass:[NSString class]]) {
        NSAssert(false, @"Parsed picture incorrectly");
    }
    if (object.from.picture && ![object.from.picture isKindOfClass:[NSString class]]) {
        NSAssert(false, @"Parsed from picture incorrectly");
    }
    
    object.originalObject = dict;
    [self setCommentsFromDict:dict onFacebookObject:object];
    [self setLikesFromDict:dict onFacebookObject:object];
    return object;
}



#pragma mark - Connection Builders



+(FacebookObject*) createHomeConnectionForObject:(FacebookObject*) object withName:(NSString*) name{
    NSString *userID = object.objectID;
    NSString *pictureURL = object.from.picture ? object.from.picture : object.picture;
    
    FacebookObject *source = [[FacebookObject alloc] init];
    source.objectID = object.objectID;
    source.name = name;
    source.type = FacebookObjectTypeMixed;
    source.additionalInfo = FacebookClientMultiQuery;
    source.icon = @"User.png"; 
    NSMutableArray *connections = [NSMutableArray array];
    
    FacebookObject *mixed = [[FacebookObject alloc] init];
    mixed.type = FacebookObjectTypeMixed;
    mixed.objectID = object.objectID;
    mixed.connectionType = @"home/feed";
    mixed.fql = [FacebookClient newsFeedQueryForUser:userID limit:kAHSwiftInitialCellLimit];
    mixed.additionalInfo = FacebookClientMultiQuery;
    mixed.name = @"All";
    mixed.picture = pictureURL;
    [connections addObject:mixed]; 
    
    FacebookObject *photos = [[FacebookObject alloc] init];
    [connections addObject:photos];
    photos.name = @"Photos";
    photos.objectID = object.objectID;
    photos.connectionType = @"home/photos";
    photos.fql = [FacebookClient streamQueryForUser:userID andType:FacebookObjectTypePhoto limit:kAHSwiftInitialCellLimit updatedTime:0];
    photos.additionalInfo = FacebookClientMultiQuery;
    photos.picture = pictureURL;
    photos.type = FacebookObjectTypePhoto;
    
    FacebookObject *links = [[FacebookObject alloc] init];    
    links.name = @"Links";
    links.type = FacebookObjectTypeLink;
    links.objectID = object.objectID;
    links.connectionType = @"home/links";
    links.fql = [FacebookClient streamQueryForUser:userID andType:FacebookObjectTypeLink limit:kAHSwiftInitialCellLimit updatedTime:0];
    links.additionalInfo = FacebookClientMultiQuery;
    links.picture = pictureURL;
    [connections addObject:links]; 
    
    FacebookObject *statuses = [[FacebookObject alloc] init];
    statuses.name = @"Status Updates";
    statuses.type = FacebookObjectTypeStatus;
    statuses.objectID = object.objectID;
    statuses.connectionType = @"home/statuses";
    statuses.fql = [FacebookClient streamQueryForUser:userID andType:FacebookObjectTypeStatus limit:kAHSwiftInitialCellLimit updatedTime:0];
    statuses.additionalInfo = FacebookClientMultiQuery;
    statuses.picture = pictureURL;
    [connections addObject:statuses]; 
    
    source.connections = connections;
    return source;
}


+(FacebookObject*) createFeedConnectionForObject:(FacebookObject*) object withName:(NSString*) name {
    NSString *objectID = object.objectID;
    NSString *pictureURL = object.from.picture ? object.from.picture : object.picture;
    
    FacebookObject *feed = [[FacebookObject alloc] init];
    feed.objectID = objectID;
    feed.name = name;
    feed.type = FacebookObjectTypeMixed;
    feed.icon = @"User.png";
    NSMutableArray *connections = [NSMutableArray array];
    
    FacebookObject *mixed = [[FacebookObject alloc] init];
    mixed.objectID = objectID;
    mixed.name = @"All";
    mixed.type = FacebookObjectTypeMixed;
    mixed.connectionType = FacebookObjectConnectionTypeFeed;
    mixed.parent = feed;
    mixed.picture = pictureURL;
    [connections addObject:mixed]; 
    
    FacebookObject *photos = [[FacebookObject alloc] init];
    photos.objectID = objectID;
    photos.name = @"Recent Photos";
    photos.type = FacebookObjectTypePhoto;
    photos.connectionType = FacebookObjectConnectionTypePhotos;
    photos.parent = feed;
    photos.picture = pictureURL;
    [connections addObject:photos]; 
    
    
    FacebookObject *links = [[FacebookObject alloc] init];
    links.objectID = objectID;
    links.name = @"Links";
    links.type = FacebookObjectTypeLink;
    links.connectionType = FacebookObjectConnectionTypeLinks;
    links.parent = feed;
    links.picture = pictureURL;
    [connections addObject:links]; 
    
    FacebookObject *statuses = [[FacebookObject alloc] init];
    statuses.objectID = objectID;
    statuses.name = @"Status Updates";
    statuses.type = FacebookObjectTypeStatus;
    statuses.connectionType = FacebookObjectConnectionTypeStatuses;
    statuses.parent = feed;
    statuses.picture = pictureURL;
    [connections addObject:statuses]; 
    
    feed.connections = connections;
    return feed;
}

+(NSArray*) connectionsForObject:(FacebookObject *)object {
    
    // Creates typical connections on the object based on the object type
    NSMutableArray *connections = [NSMutableArray array];    
    
    // TODO: create Favorites connection if user is current user 
    
    // Only current users should be able to see news feed
    if ([object.objectID isEqualToString:[self currentUserID]] || [object.objectID isEqualToString:@"me"]) {
        FacebookObject *newsFeedConnection = [self createHomeConnectionForObject:object withName:@"News Feed"];
        newsFeedConnection.connectionType = FacebookObjectConnectionTypeHome;
        [connections addObject:newsFeedConnection];
    }
    
    // Feed
    FacebookObject *wallConnection = [self createFeedConnectionForObject:object withName:@"Wall"];
    [connections addObject:wallConnection];
    
    //Albums
    FacebookObject *photosAndVideosConnection = [[FacebookObject alloc] init];
    photosAndVideosConnection.name = @"Albums";
    photosAndVideosConnection.type = FacebookObjectTypePhoto;
    photosAndVideosConnection.connectionType = FacebookObjectConnectionTypeAlbums;
    photosAndVideosConnection.icon = @"User.png";
    //We need to add a photos connection for each album, let's see if we have the albums yet
    if (object.albums) {
        NSMutableArray *albumConnections = [NSMutableArray arrayWithCapacity:object.albums.count];
        for (FacebookObject *album in object.albums) {
            FacebookObject *albumConnection = [album copy];
            albumConnection.connectionType = FacebookObjectConnectionTypePhotos;
            albumConnection.type = FacebookObjectTypePhoto;
            [albumConnections addObject:albumConnection];
        }
        photosAndVideosConnection.connections = albumConnections;
    }
    [connections addObject:photosAndVideosConnection];
    
    //Friends
    FacebookObject *friendsConnection = [[FacebookObject alloc] init];
    friendsConnection.objectID = object.objectID;
    friendsConnection.name = @"Friends";
    friendsConnection.type = FacebookObjectTypePhoto;
    friendsConnection.icon = @"User.png";
    
    FacebookObject *groupsConnection = [[FacebookObject alloc] init];
    groupsConnection.objectID = object.objectID;
    groupsConnection.name = @"Groups";
    groupsConnection.type = FacebookObjectTypePhoto;
    groupsConnection.icon = @"Group.png"; 
    groupsConnection.connectionType = [NSString stringWithFormat:@"%@/groups", object.objectID];
    if (object.groups) {
        NSMutableArray *feedConnections = [NSMutableArray arrayWithCapacity:object.groups.count];
        for (FacebookObject *group in object.groups) {
            FacebookObject *groupConnection = [group copy];
            groupConnection.connectionType = FacebookObjectConnectionTypeGroups;
            groupConnection.type = FacebookObjectTypeMixed;
            [feedConnections addObject:groupConnection];
        }
        groupsConnection.connections = feedConnections;
    }    
    [connections addObject:groupsConnection];
    
    
    //likes
    FacebookObject *likesConnection = [[FacebookObject alloc] init];
    likesConnection.name = @"Likes";
    likesConnection.type = FacebookObjectTypePhoto;
    likesConnection.connectionType = [NSString stringWithFormat:@"%@/likes", object.objectID];
    likesConnection.icon = @"ActionHeartDefault.png";
    
    if (object.likes) {
        NSMutableArray *feedConnections = [NSMutableArray arrayWithCapacity:object.likes.count];
        for (FacebookObject *like in object.likes) {
            FacebookObject *likeConnection = [like copy];
            likeConnection.connectionType = FacebookObjectConnectionTypeFeed;
            likeConnection.type = FacebookObjectTypeMixed;
            [feedConnections addObject:likeConnection];
        }
        likesConnection.connections = feedConnections;
    }
    [connections addObject:likesConnection];
    
    
    // Current User only
    if ([object.objectID isEqualToString:[self currentUserID]]) {
        
        // A complete list of the user's friends can only currently be retrieved for the user's current friends
        friendsConnection.connectionType = [NSString stringWithFormat:@"%@/friends", object.objectID];
        if (object.friends) {
            NSMutableArray *feedConnections = [NSMutableArray arrayWithCapacity:object.friends.count];
            for (FacebookObject *friend in object.friends) {
                FacebookObject *friendConnection = [friend copy];
                friendConnection.connectionType = FacebookObjectConnectionTypeFeed;
                friendConnection.type = FacebookObjectTypeMixed;
                [feedConnections addObject:friendConnection];
            }
            friendsConnection.connections = feedConnections;
        }
        [connections addObject:friendsConnection];
        
        //Friendlists
        FacebookObject *friendlistsConnection = [[FacebookObject alloc] init];
        friendlistsConnection.name = @"Friend Lists";
        friendlistsConnection.type = FacebookObjectTypePhoto;
        friendlistsConnection.connectionType = FacebookObjectConnectionTypeFriendLists;
        friendlistsConnection.icon = @"Group.png";
        if (object.friendlists) {
            NSMutableArray *feedConnections = [NSMutableArray arrayWithCapacity:object.friendlists.count];
            for (FacebookObject *friendlist in object.friendlists) {
                FacebookObject *friendlistConnection = [friendlist copy];
                friendlistConnection.connectionType = @"members";
                friendlistConnection.type = FacebookObjectTypeMixed;
                [feedConnections addObject:friendlistConnection];
            }
            friendlistsConnection.connections = feedConnections;
        }    
        [connections addObject:friendlistsConnection];
    }
    
    //    source = [[FacebookObject alloc] init];:@"LISTS"];
    //    source.isExpandable = YES;
    //    [organizerSources addObject:source];
    //    NSArray *friendlists = [me valueForKey:@"friendlists"];
    //    NSInteger friendlistsLimit = 5;
    //    for (NSDictionary *friendlist in friendlists) {
    //        if (friendlistsLimit > 0) {
    ////            NSString *path = [NSString stringWithFormat:@"%@/feed", [friendlist valueForKey:@"id"]];
    ////            [organizerSources addObject:[self createExplodedSourceWithTitle:[friendlist valueForKey:@"name"] path:path]];
    //            friendlistsLimit -=1;
    //        }
    //    }
    
    
    return connections;
}



#pragma mark -
#pragma mark URL builders


+ (NSString*) buildMultiQuery:(NSDictionary*) queryDict {
    return [NSString stringWithFormat:@"fql?q=%@", [queryDict JSONString]];
}

+(NSString*) streamSQLforFilter:(NSString*) whereClause limit:(NSInteger) limit {
    return [NSString stringWithFormat:@"SELECT created_time, updated_time, attachment, post_id, source_id, actor_id, target_id, message, likes, privacy, tagged_ids, message_tags, description, description_tags, type FROM stream WHERE %@  limit %ld", whereClause, limit];
}

+ (NSString*) commentsQueryReferencingQueryWithName:(NSString*) name {
    return [NSString stringWithFormat:@"select post_id, fromid, object_id, text, time, can_like, user_likes from comment where post_id in (SELECT post_id FROM #%@)", name];
}

+(NSString*) profileQueryReferencingQueryWithName:(NSString*) name {
    return [NSString stringWithFormat:@"SELECT name, id FROM profile WHERE id IN (SELECT actor_id FROM #%@) or id in (select fromid from #commentsQuery)", name];
}


+(NSString*) streamFilterForFacebookObjectType:(FacebookObjectType) type {
    NSString *filterClause = [NSString stringWithFormat:@"filter_key=\'%@\'", [self filterKeyForFacebookObjectType:type]];
    if (type == FacebookObjectTypeStatus) {
        filterClause = [NSString stringWithFormat:@"%@ and type=\'%@\'", filterClause, [self storyTypeForFacebooObjectType:type]];
    }
    return filterClause;
}

+ (NSString*) storyTypeForFacebooObjectType:(FacebookObjectType) type {
    switch (type) {
        case FacebookObjectTypePhoto:
            return @"247";
            break;
        case FacebookObjectTypeStatus:
            return @"46";
            break;
        case FacebookObjectTypeLink:
            return @"80";
            break;
        case FacebookObjectTypeVideo:
            return @"128";
            break;
        default:
            break;
    }
    return @"";
}

+(NSString*) filterKeyForFacebookObjectType:(FacebookObjectType) type {
    switch (type) {
        case FacebookObjectTypePhoto:
            return @"app_2305272732_2392950137";
            break;
        case FacebookObjectTypeLink:
            return @"app_2309869772";
            break;
        case FacebookObjectTypeMixed:
            return @"nf";
            break;
        case FacebookObjectTypeStatus:
            return @"app_2915120374";
            break;
        default:
            break;
    }
    return nil;
}


+(NSString*) streamQueryForUser:(NSString*) userID andType:(FacebookObjectType) type limit:(NSInteger) limit updatedTime:(NSInteger) updatedTime {
    NSString *filterString = [self streamFilterForFacebookObjectType:type];  //[NSString stringWithFormat:@"filter_key in (SELECT filter_key FROM stream_filter WHERE uid = %@ AND type = 'newsfeed')", userID];
    if (updatedTime > 0) {
        filterString = [NSString stringWithFormat:@"%@ and updated_time > %ld", filterString, updatedTime];
    }
    NSMutableDictionary *queriesDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [queriesDict setValue:[self streamSQLforFilter:filterString limit:limit] forKey:@"streamQuery"];
    [queriesDict setValue:[self profileQueryReferencingQueryWithName:@"streamQuery"] forKey:@"profileQuery"];
    [queriesDict setValue:[self commentsQueryReferencingQueryWithName:@"streamQuery"] forKey:@"commentsQuery"];
    return [self buildMultiQuery:queriesDict];
}

+(NSString*) newsFeedQueryForUser:(NSString*) userID limit:(NSInteger) limit {
    return [self streamQueryForUser:userID andType:FacebookObjectTypeMixed limit:limit updatedTime:0];
}


#pragma mark - Helpers


+ (NSString*)urlForRequest:(NSString*) request andParams:(NSDictionary*) params {
    NSString *escapedRequest = [request stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *accessToken = [FacebookClient accessToken];
    NSString *url = nil;
    if ([escapedRequest containsString:@"http://"]) url = escapedRequest;
    else url = [NSString stringWithFormat: FacebookClientGraphApiGetURL, escapedRequest];
    
    if (![escapedRequest containsString:@"?"]) url = [url stringByAppendingFormat:@"?access_token=%@", accessToken];
    else url = [url stringByAppendingFormat:@"&access_token=%@", accessToken];
    
    // make sure all dates are returned as unix timestamps
    url = [url stringByAppendingString:@"&date_format=U"];
    
    if (params != nil) 
    {
        NSMutableString *strWithParams = [NSMutableString stringWithString: url];
        for (NSString *p in [params allKeys]) 
            [strWithParams appendFormat: @"&%@=%@", p, [params objectForKey: p]];
        url = strWithParams;
    }
    return url;
}


+ (void)utfAppendBody:(NSMutableData *)body data:(NSString *)data {
    [body appendData:[data dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSMutableData *)generatePostBody :(NSDictionary*)_params {
    
    //NSString* kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";
    NSMutableData *body = [NSMutableData data];
    NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kJokinglyPostRequestStringBoundary];
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    
    [self utfAppendBody:body data:[NSString stringWithFormat:@"--%@\r\n", kJokinglyPostRequestStringBoundary]];
    
    for (id key in [_params keyEnumerator]) {
        
        if (([[_params valueForKey:key] isKindOfClass:[NSData class]])) {
            
            [dataDictionary setObject:[_params valueForKey:key] forKey:key];
            continue;
            
        }
        
        [self utfAppendBody:body
                       data:[NSString
                             stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",
                             key]];
        [self utfAppendBody:body data:[_params valueForKey:key]];
        
        [self utfAppendBody:body data:endLine];
    }
    
    if ([dataDictionary count] > 0) {
        for (id key in dataDictionary) {
            NSObject *dataParam = [dataDictionary valueForKey:key];
            if ([dataParam isKindOfClass:[NSData  class]]) {
                [self utfAppendBody:body  data:[NSString stringWithFormat:  @"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
                [self utfAppendBody:body  data:@"Content-Type: image/png\r\n\r\n"];
                [body appendData:(NSData*)dataParam];
            }             
            [self utfAppendBody:body data:endLine];
            
        }
    }
    
    return body;
}


+ (NSArray*) sortFriendsByName:(NSArray*) friends {
    if (!friends) return nil;
    return [friends sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *name1 = [obj1 valueForKey:@"name"];
        NSString *name2 = [obj2 valueForKey:@"name"];
        return [name1 caseInsensitiveCompare:name2];
    }];
}

+(NSString*) userIdForURL:(NSString *) url {
    if ([url hasPrefix:@"me"]) {
        return @"me";
    }
    return [[url componentsSeparatedByString:@"/"] objectAtIndex:0];
}


+ (JokinglyJSONHandler) jsonHandler {
    JokinglyJSONHandler jsonHandler;
    jsonHandler = ^id(JokinglyOperation* operation, id obj) {
        if (!operation.appError) {
            if (obj && [obj isKindOfClass:[NSDictionary class]]) {
                if ([[obj allKeys] count] <= 2) {
                    NSArray *arr = [obj valueForKey:@"data"];
                    if (arr) {
                        NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:[arr count]];
                        for (id obj in arr) {
                            if ([obj isKindOfClass:[NSDictionary class]]) {
                                NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:obj];
                                [mutableArray addObject:mutableDict];
                            } else [mutableArray addObject:obj];
                        }
                        return mutableArray;
                    }
                }
            }
        }
        return nil;
    };
    return jsonHandler;
}


+ (JokinglyHandler) checkForErrorHandler {
    JokinglyHandler checkForErrorHandler;
    checkForErrorHandler = ^(JokinglyOperation* operation) {
        if (operation.result && [operation.result isKindOfClass:[NSDictionary class]]) {
            NSDictionary *error  = [operation.result valueForKey:@"error"];
            if (error) {
                NSString *message = [error valueForKey:@"message"];
                operation.appError = [NSString stringWithFormat:@"Bad FB request %@", message];
                NSLog(@"%@", operation.appError);
            }
        }
    };
    return checkForErrorHandler;
}

+ (JokinglyHandler) errorHandler {
    JokinglyHandler errorHandler;
    errorHandler = ^(JokinglyOperation* operation) {
        // Publish any error
        // Check for HTTP error, FB errors are returned inside the HTTP body
        if(operation.connectionError) {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:FacebookClientConnectionError object:nil]];
            return;
        }
        
        if (operation.appError) {
            if ([operation.appError containsString:@"Invalid OAuth"]) {
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:FacebookClientRejectedAccessToken object:nil]];
            }
        }
        
    };
    return errorHandler;
}

# pragma mark - Properties

+ (NSOperationQueue *)operationQueue {
    static NSOperationQueue *operationQueue;
    
    if (!operationQueue) {
        operationQueue = [[NSOperationQueue alloc] init]; 
        operationQueue.maxConcurrentOperationCount = 15;
    }
    
    return operationQueue;
}

+ (NSString*) accessToken {
    NSString * accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:FacebookClientAccessToken];
    return accessToken;
}

+ (NSString*) accessTokenExpiration {
    return [[NSUserDefaults standardUserDefaults] valueForKey:FacebookClientStoreTokenExpiry];
}

+ (NSString*) accessPermissions {
    return [[NSUserDefaults standardUserDefaults] valueForKey:FacebookClientStoreAccessPermissions];    
}

+ (void) setAccessToken:(NSString*) accessToken {
    [[NSUserDefaults standardUserDefaults] setValue:accessToken forKey:FacebookClientAccessToken];
}

+ (void) setAccessTokenExpiration:(NSDate*) accessTokenExpiration {
    [[NSUserDefaults standardUserDefaults] setValue:accessTokenExpiration forKey:FacebookClientStoreTokenExpiry];
}

+ (void) setAccessPermissions:(NSString*) accessPermissions {
    [[NSUserDefaults standardUserDefaults] setValue:accessPermissions forKey:FacebookClientStoreAccessPermissions];
}

+ (NSString*) currentUserID {
    NSString *userID = [[NSUserDefaults standardUserDefaults] valueForKey:FacebookClientCurrentUserID];
    return userID;
}

+ (void) setCurrentUserID:(NSString*) userID {
    [[NSUserDefaults standardUserDefaults] setValue:userID forKey:FacebookClientCurrentUserID];
}

+(void) flushCache {
    NSString *currentUserId = [self currentUserID];
    NSString *cacheFileKey = [NSString stringWithFormat:@"%@-tempdir", currentUserId];
    NSString *cacheDir = [[NSUserDefaults standardUserDefaults] valueForKey:cacheFileKey];
    BOOL cacheExists = NO;
    if (cacheDir) {
        [[NSFileManager defaultManager] fileExistsAtPath:cacheDir isDirectory:&cacheExists];
    }
    
    if (cacheDir &&cacheExists) {
        [[NSFileManager defaultManager] removeItemAtPath:cacheDir error:nil];
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:cacheFileKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+(NSString*) tempCacheDir {
    NSString *currentUserId = [self currentUserID];
    NSString *cacheFileKey = [NSString stringWithFormat:@"%@-tempdir", currentUserId];
    NSString *cacheDir = [[NSUserDefaults standardUserDefaults] valueForKey:cacheFileKey];
    BOOL cacheExists = NO;
    if (cacheDir) {
        [[NSFileManager defaultManager] fileExistsAtPath:cacheDir isDirectory:&cacheExists];
    }
    
    if (!cacheDir || !cacheExists) {
        cacheDir = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] absoluteString];
        [[NSUserDefaults standardUserDefaults] setValue:cacheDir forKey:cacheFileKey];
    }
    return cacheDir;
}

+(NSString*) jsonCachePath {
    //NSString *currentUserId = [self currentUserID];
    //NSString * jsonCachePath =[[NSFileManager defaultManager] findOrCreateTempDir:[NSString stringWithFormat:@"com.airheart.Swift/%@/json", currentUserId]];
    NSString * jsonCachePath = [self tempCacheDir];
    return jsonCachePath;
}

+(NSString*) photosCachePath {
    //NSString *currentUserId = [self currentUserID];
    //NSString * photoCachePath = [[NSFileManager defaultManager] findOrCreateTempDir:[NSString stringWithFormat:@"AirHeart.Swift/%@/photos", currentUserId]];
    NSString * photoCachePath = [self tempCacheDir];
    return photoCachePath;
}


#pragma mark - Archiving objects

+(FMDatabase*) openDatabase {
    FMDatabase *db = [FMDatabase databaseWithPath:@"/tmp/swift.db"];
    if (![db open]) {
        return nil;
    }
    static BOOL createdDB = NO;
    if (!createdDB) {
        //Create the database
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS objects ( \"id\" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \"key\" TEXT NOT NULL, \"updated\" integer not null, \"uuid\" TEXT NOT NULL, \"data\" BLOB NOT NULL);"];
        createdDB = YES;
    }
    return db;
}

+(FacebookObject*) readObjectWithKey:(NSString*) key {
    FMDatabase *db = [self openDatabase];
    FMResultSet *rs = [db executeQuery:@"select data from objects where key =?" withArgumentsInArray:[NSArray arrayWithObjects:key, nil]];
    if (rs.next) {
        NSData *data = [rs dataForColumnIndex:0];
        FacebookObject *object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        return object;
    }
    return nil;
}

+(void) saveObject:(FacebookObject*) object withKey:(NSString*) key {
    BOOL newObject = NO;
    if (!object.uuid) {
        newObject = YES;
        object.uuid = [NSString stringWithUUID];
    }
    object.updatedAt = [NSDate date];
    FMDatabase *db = [self openDatabase];
    NSNumber* timestamp = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:object];
    if (!newObject) {
        [db executeUpdate:@"update objects set updated=?, data =? where uuid=? " withArgumentsInArray:[NSArray arrayWithObjects:timestamp, data, object.uuid, nil]];
    } else {
        [db executeUpdate:@"insert into objects (key, updated, uuid, data) values(?, ?, ?, ?)" withArgumentsInArray:[NSArray arrayWithObjects: key, timestamp, object.uuid, data, nil]];
    }
}

+(void) flushObjectWithId:(NSString*) objectId {
    
}


@end
