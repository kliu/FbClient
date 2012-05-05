//
//  FacebookObject.m
//  Swift
//
//  Created by John Wright on 2/7/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "FacebookObject.h"

NSString *const kFacebookPrivacyOnlyMe  =@"SELF";
NSString *const kFacebookPrivacyPublic  =@"EVERYONE";
NSString *const kFacebookPrivacyFriends =@"ALL_FRIENDS";
NSString *const kFacebookPrivacyCustom  =@"CUSTOM";


@implementation NSString (FacebookObjectTypeParser)

- (FacebookObjectType)FacebookObjectTypeFromString{
    NSDictionary *FacebookObjectTypes  = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInteger:FacebookObjectTypeLink], @"link",
                               [NSNumber numberWithInteger:FacebookObjectTypePhoto], @"photo",
                               [NSNumber numberWithInteger:FacebookObjectTypeVideo], @"video",
                               [NSNumber numberWithInteger:FacebookObjectTypeStatus], @"status",
                               [NSNumber numberWithInteger:FacebookObjectTypeCheckin], @"checkin",
                               [NSNumber numberWithInteger:FacebookObjectTypeActivity], @"activity",
                               [NSNumber numberWithInteger:FacebookObjectTypeVideo], @"video",
                               [NSNumber numberWithInteger:FacebookObjectTypeUser], @"user", 
                              [NSNumber numberWithInteger:FacebookObjectTypeAlbum], @"album", 
                              [NSNumber numberWithInteger:FacebookObjectTypePage], @"page", 
                              [NSNumber numberWithInteger:FacebookObjectTypeFriendlist], @"friendlist", 
                              [NSNumber numberWithInteger:FacebookObjectTypeGroup], @"group", 
                               [NSNumber numberWithInteger:FacebookObjectTypeMixed], @"mixed", 
                               nil
                               ];
    NSNumber *FacebookObjectTypeNumber = [FacebookObjectTypes objectForKey:self];
    if (FacebookObjectTypeNumber) {
        return (FacebookObjectType)[FacebookObjectTypeNumber intValue];
    }
    return FacebookObjectTypeStatus;
}
@end

@implementation FacebookObject

// Common Core FB properties
@synthesize uuid;
@synthesize objectID;
@synthesize type;

@synthesize parent;
@synthesize connectionType;
@synthesize connections;

@synthesize createdAt;
@synthesize updatedAt;

@synthesize toID;
@synthesize toName;
@synthesize name;
@synthesize message;
@synthesize link;
@synthesize description;
@synthesize picture;
@synthesize icon;
@synthesize caption;
@synthesize source;
@synthesize isVideo;
@synthesize originalObject;
@synthesize additionalInfo;
@synthesize imageBinary;
@synthesize installed;
// Convenience functions for us
@synthesize cannotLike;
@synthesize wasLikedByCurrentUser;
@synthesize likeCount;

@synthesize fql;

@synthesize cannotComment;
@synthesize wasCommentedOnByCurrentUser;
@synthesize commentCount;

@synthesize from;
@synthesize album;

@synthesize data;
@synthesize comments;
@synthesize likes;
@synthesize groups;
@synthesize pages;
@synthesize friends;
@synthesize friendlists;
@synthesize photos;
@synthesize albums;
@synthesize closeFriends;


+(BOOL)AMCEnabled {
    return YES;
}

+(FacebookObject*) facebookObjectWithID:(NSString*) objectID {
    FacebookObject *facebookObject = [[FacebookObject alloc] init];
    facebookObject.objectID = objectID;
    return facebookObject;
}

-(NSString*) description {
    return [NSString stringWithFormat:@" objectID: %@\n type: %d\n name: %@\n message: %@\n description: %@\n fromID: %@\n fromName: %@\ninstalled = %d\n", objectID, type, name, message, description, from.objectID, from.name, installed];
}

- (id)copyWithZone:(NSZone *)zone {
    FacebookObject *result = [[FacebookObject alloc] init];
    result.uuid = self.uuid;
    result.objectID = self.objectID;
    result.createdAt = self.createdAt;
    result.parent = self.parent;
    result.connectionType = self.connectionType;
    result.updatedAt = self.updatedAt;
    result.name = self.name ;
    result.message = self.message;
    result.type = self.type;
    result.link = self.link;
    result.description = self.description;
    result.picture = self.picture;
    result.caption = self.caption;
    result.source = self.source;
    result.isVideo = self.isVideo;
    result.originalObject = self.originalObject;
    result.cannotLike = self.cannotLike;
    result.wasLikedByCurrentUser = self.wasLikedByCurrentUser;
    result.wasCommentedOnByCurrentUser = self.wasCommentedOnByCurrentUser;
    result.likeCount = self.likeCount;
    result.cannotComment = self.cannotComment;
    result.commentCount = self.commentCount;
    result.installed = self.installed;
    result.icon = self.icon;
  
    result.fql= self.fql;
    
    result.from = self.from;
    result.album = self.album;
    
    if (self.connections) result.connections = [self.connections copyWithZone:zone];
    if (self.data ) result.data = [self.data copyWithZone:zone];
    if (self.comments) result.comments = [self.comments copyWithZone:zone];
    if (self.likes) result.likes = [self.likes copyWithZone:zone];
    if (self.groups) result.groups = [self.groups copyWithZone:zone];
    if (self.friendlists) result.friendlists = [self.friendlists copyWithZone:zone];
    if (self.friends) result.friends = [self.friends copyWithZone:zone];
    if (self.photos) result.photos = [self.photos copyWithZone:zone];
    if (self.albums) result.albums = [self.albums  copyWithZone:zone];
    if (self.pages) result.likes = [self.pages copyWithZone:zone];
    if (self.closeFriends) result.likes = [self.closeFriends copyWithZone:zone];
    return result;
}


- (id)initWithCoder:(NSCoder *)coder
{
    if(self = [self init]){
        uuid = [coder decodeObjectForKey:@"uu"];
        objectID = [coder decodeObjectForKey:@"oi"];
        parent = [coder decodeObjectForKey:@"par"];
        createdAt = [coder decodeObjectForKey:@"ca"];
        connectionType = [coder decodeObjectForKey:@"ga"];
        updatedAt = [coder decodeObjectForKey:@"ua"];
        name = [coder decodeObjectForKey:@"na"];
        message = [coder decodeObjectForKey:@"me"];
        type = [coder decodeInt32ForKey:@"ty"];
        link = [coder decodeObjectForKey:@"li"];
        description = [coder decodeObjectForKey:@"de"];
        picture = [coder decodeObjectForKey:@"pi"];
        caption = [coder decodeObjectForKey:@"cap"];
        source  = [coder decodeObjectForKey:@"sou"];
        isVideo = [coder decodeBoolForKey:@"iv"];
        cannotLike = [coder decodeBoolForKey:@"cl"];
        wasLikedByCurrentUser = [coder decodeBoolForKey:@"wl"];
        wasCommentedOnByCurrentUser = [coder decodeBoolForKey:@"wc"];
        likeCount = [coder decodeObjectForKey:@"lc"];
        cannotComment = [coder decodeBoolForKey:@"cco"];
        commentCount = [coder decodeObjectForKey:@"ccou"];
        originalObject = [coder decodeObjectForKey:@"oo"];
        icon = [coder decodeObjectForKey:@"ic"];
        
        fql = [coder decodeObjectForKey:@"fql"];
        
        from = [coder decodeObjectForKey:@"fr"];
        album = [coder decodeObjectForKey:@"alb"];
        
        connections = [coder decodeObjectForKey:@"con"];
        data = [coder decodeObjectForKey:@"fe"];
        likes = [coder decodeObjectForKey:@"lik"];
        comments = [coder decodeObjectForKey:@"co"];
        pages    = [coder decodeObjectForKey:@"pa"];
        groups = [coder decodeObjectForKey:@"gr"];
        photos = [coder decodeObjectForKey:@"ph"];
        albums = [coder decodeObjectForKey:@"al"];
        friends = [coder decodeObjectForKey:@"fri"];
        friendlists = [coder decodeObjectForKey:@"fl"];
        
        closeFriends = [coder decodeObjectForKey:@"cf"];
        installed = [coder decodeBoolForKey:@"in"];

    }
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:uuid forKey:@"uu"];
	[coder encodeObject:objectID forKey:@"oi"];
    [coder encodeObject:parent forKey:@"par"];
    [coder encodeObject:connectionType forKey:@"ga"];
    [coder encodeObject:createdAt forKey:@"ca"];
    [coder encodeObject:updatedAt forKey:@"ua"];
    [coder encodeObject:name forKey:@"na"];
    [coder encodeObject:message forKey:@"me"];
    [coder encodeInt32:type forKey:@"ty"];
    [coder encodeObject:link forKey:@"li"];
    [coder encodeObject:description forKey:@"de"];
    [coder encodeObject:picture forKey:@"pi"];
    [coder encodeObject:caption forKey:@"cap"];
    [coder encodeObject:source forKey:@"sou"];
    [coder encodeBool:isVideo forKey:@"iv"];
    [coder encodeBool:cannotLike forKey:@"cl"];
    [coder encodeBool:wasLikedByCurrentUser forKey:@"wl"];
    [coder encodeBool:wasCommentedOnByCurrentUser forKey:@"wc"];
    [coder encodeBool:cannotComment forKey:@"cco"];
    [coder encodeObject:likeCount forKey:@"lc"];
    [coder encodeObject:commentCount forKey:@"ccou"];
    [coder encodeObject:originalObject forKey:@"oo"];
    [coder encodeObject:icon forKey:@"ic"];
    
    
    [coder encodeObject:fql forKey:@"fql"];
    
    [coder encodeObject:from forKey:@"fr"];
    [coder encodeObject:album forKey:@"alb"];

    
    [coder encodeObject:connections forKey:@"con"];
    [coder encodeObject:data forKey:@"fe"];
    [coder encodeObject:likes forKey:@"lik"];
    [coder encodeObject:comments forKey:@"co"];
    [coder encodeObject:pages forKey:@"pa"];
    [coder encodeObject:groups forKey:@"gr"];
    [coder encodeObject:photos  forKey:@"al"];
    [coder encodeObject:albums forKey:@"ph"];
    [coder encodeObject:friends forKey:@"fri"];
    [coder encodeObject:friendlists forKey:@"fl"];
    [coder encodeObject:closeFriends forKey:@"cf"];
    [coder encodeBool:installed forKey:@"in"];
    
}

-(BOOL) isEqual:(id)object {
    FacebookObject *otherObject = (FacebookObject*) object;
    return [otherObject.objectID isEqualToString:self.objectID];
}

-(NSString*) graphPath {
    if (fql) return fql;
    if (!objectID) return nil;
    if (!connectionType) {
        return objectID;
    }
    return [NSString stringWithFormat:@"%@/%@", objectID, connectionType];
}

-(FacebookObject*) homeConnection {
    return [self findConnectionByType:FacebookObjectConnectionTypeHome];
}

-(FacebookObject*) feedConnection {
    return [self findConnectionByType:FacebookObjectConnectionTypeFeed];
}

-(FacebookObject*) groupsConnection {
    return [self findConnectionByType:FacebookObjectConnectionTypeGroups];
}

-(FacebookObject*) photosConnection {
    return [self findConnectionByType:FacebookObjectConnectionTypePhotos];
}

-(FacebookObject*) albumsConnection {
    return [self findConnectionByType:FacebookObjectConnectionTypeAlbums];
}

-(FacebookObject*) statusesConnection {
    return [self findConnectionByType:FacebookObjectConnectionTypeStatuses];
}

-(FacebookObject*) linksConnection {
    return [self findConnectionByType:FacebookObjectConnectionTypeLinks];
}

-(FacebookObject*) findConnectionByType:(NSString*) connType {
    if (connections && connections.count) {
        NSArray *found = [self.connections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"connectionType = %@", connType]];
        if (found && found.count) {
            return [found objectAtIndex:0];
        }
    }
    return nil;
}


@end
