//
//  DAVCredentials.h
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@interface DAVCredentials : NSObject {
  @private
	NSString *_username;
	NSString *_password;
}

@property (strong, readonly) NSString *username;
@property (strong, readonly) NSString *password;

+ (id)credentialsWithUsername:(NSString *)username password:(NSString *)password;

- (id)initWithUsername:(NSString *)username password:(NSString *)password;

@end
