//
//  DAVRequest.h
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "DAVBaseRequest.h"

@protocol DAVRequestDelegate;

/* codes returned are HTTP status codes */
extern NSString *const DAVClientErrorDomain;

@interface DAVRequest : DAVBaseRequest {
  @private
	NSString *_path;
	NSURLConnection *_connection;
	NSMutableData *_data;
	BOOL _done, _cancelled;
	BOOL _executing;
}

@property (strong, readonly) NSString *path;

@property (weak) id < DAVRequestDelegate > delegate;
@property (nonatomic, copy) void (^successCallback)(id result);
@property (nonatomic, copy) void (^failureCallback)(NSError* error);
@property (nonatomic, copy) void (^progressCallback)(id data);

- (id)initWithPath:(NSString *)aPath;

- (NSURL *)concatenatedURLWithPath:(NSString *)aPath;

/* must be overriden by subclasses */
- (NSURLRequest *)request;

/* optional override */
- (id)resultForData:(NSData *)data;

/* override when it is a long operation
   If returning YES the data received won't be cached, otherwise it will be cached */
- (BOOL)dataReceived:(NSData *)data;

@end


@protocol DAVRequestDelegate < NSObject >

// The error can be a NSURLConnection error or a WebDAV error
- (void)request:(DAVRequest *)aRequest didFailWithError:(NSError *)error;

// The resulting object varies depending on the request type
- (void)request:(DAVRequest *)aRequest didSucceedWithResult:(id)result;

@optional

- (void)requestDidBegin:(DAVRequest *)aRequest;

@end
