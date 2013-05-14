//
//  DAVBaseRequest.h
//  DAVKit
//
//  Copyright Matt Rajca 2011. All rights reserved.
//

#import <Foundation/NSOperation.h>
#import <Foundation/NSURL.h>

@class DAVCredentials;

@interface DAVBaseRequest : NSOperation {
	
}

@property (strong) NSURL *rootURL;
@property (strong) DAVCredentials *credentials;
@property (assign) BOOL allowUntrustedCertificate;
@property (readonly) BOOL isLongRequest;

@end
