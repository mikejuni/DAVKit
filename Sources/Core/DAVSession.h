//
//  DAVSession.h
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

@class DAVCredentials;
@class DAVBaseRequest;

/* All paths are relative to the root of the server */

@interface DAVSession : NSObject {
  @private
	NSURL *_rootURL;
	DAVCredentials *_credentials;
	NSOperationQueue *_queue;
    NSOperationQueue *_longOperationQueue;
}

@property (strong, readonly) NSURL *rootURL;
@property (strong, readonly) DAVCredentials *credentials;
@property (assign) BOOL allowUntrustedCertificate;
@property (strong, nonatomic) NSOperationQueue* queue;
@property (strong, nonatomic) NSOperationQueue* longOperationQueue;

@property (readonly) NSUInteger requestCount; /* KVO compliant */
@property (readonly) NSUInteger longRequestCount; /* KVO compliant */
@property (assign) NSInteger maxConcurrentRequests; /* default is 2 */
@property (assign) NSInteger maxLongConcurrentRequests;

/*
 The root URL should include a scheme and host, followed by any root paths
 **NOTE: omit the trailing slash (/)**
 Example: http://idisk.me.com/steve
*/
- (id)initWithRootURL:(NSURL *)url credentials:(DAVCredentials *)credentials;

- (void)enqueueRequest:(DAVBaseRequest *)aRequest;
- (void)cancelRequests;
- (void)cancelLongRequests;

- (void)resetCredentialsCache;

@end

