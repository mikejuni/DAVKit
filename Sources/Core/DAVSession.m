//
//  DAVSession.m
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "DAVSession.h"

#import "DAVRequest.h"
#import "DAVRequest+Private.h"
#import "DAVRequests.h"

@implementation DAVSession

@synthesize rootURL = _rootURL;
@synthesize credentials = _credentials;
@synthesize allowUntrustedCertificate = _allowUntrustedCertificate;
@dynamic requestCount, longRequestCount, maxConcurrentRequests, maxLongConcurrentRequests;
@synthesize queue=_queue;
@synthesize longOperationQueue=_longOperationQueue;

#define DEFAULT_CONCURRENT_REQS 2

- (id)initWithRootURL:(NSURL *)url credentials:(DAVCredentials *)credentials {
	NSParameterAssert(url != nil);
	
	if (!credentials) {
		#ifdef DEBUG
			NSLog(@"Warning: No credentials were provided. Servers rarely grant anonymous access");	
		#endif
	}
	
	self = [super init];
	if (self) {
		_rootURL = [url copy];
		_credentials = credentials;
		_allowUntrustedCertificate = NO;
		
        /*
		_queue = [[NSOperationQueue alloc] init];
		[_queue setMaxConcurrentOperationCount:DEFAULT_CONCURRENT_REQS];
		
		[_queue addObserver:self
				 forKeyPath:@"operationCount"
					options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
					context:NULL];
         */
	}
	return self;
}

- (NSOperationQueue*)queue{
    if (!_queue){
        _queue=[[NSOperationQueue alloc]init];
        [_queue setMaxConcurrentOperationCount:DEFAULT_CONCURRENT_REQS];
        
        [_queue addObserver:self forKeyPath:@"operationCount" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:@"normalQueue"];
    }
    return _queue;
}

- (void)setQueue:(NSOperationQueue *)queue{
    if (_queue){
        [_queue removeObserver:self forKeyPath:@"operationCount"];
        _queue=nil;
    }
    
    _queue=queue;
    
    [_queue addObserver:self forKeyPath:@"operationCount" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:@"normalQueue"];
}

- (void)setLongOperationQueue:(NSOperationQueue *)longOperationQueue{
    if (_longOperationQueue){
        [_longOperationQueue removeObserver:self forKeyPath:@"operationCount"];
        _longOperationQueue=nil;
    }
    
    _longOperationQueue=longOperationQueue;
    
        [_longOperationQueue addObserver:self forKeyPath:@"operationCount" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:@"longQueue" ];    
}

- (NSOperationQueue*)longOperationQueue{
    if (!_longOperationQueue) {
        _longOperationQueue=[[NSOperationQueue alloc]init];
        [_longOperationQueue setMaxConcurrentOperationCount:DEFAULT_CONCURRENT_REQS];
        
        [_longOperationQueue addObserver:self forKeyPath:@"operationCount" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:@"longQueue" ];
    }
    return _longOperationQueue;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"operationCount"]) {
        if ([((__bridge NSString*)context) isEqualToString:@"normalQueue"]){
            [self willChangeValueForKey:@"requestCount"];
            [self didChangeValueForKey:@"requestCount"];
        }else{
            [self willChangeValueForKey:@"longRequestCount"];
            [self didChangeValueForKey:@"longRequestCount"];
        }
	}
}

- (NSUInteger)requestCount {
	return [self.queue operationCount];
}

- (NSUInteger)longRequestCount{
    return [self.longOperationQueue operationCount];
}

- (NSInteger)maxConcurrentRequests {
	return [self.queue maxConcurrentOperationCount];
}

- (NSInteger)maxLongConcurrentRequests{
    return [self.longOperationQueue maxConcurrentOperationCount];
}

- (void)setMaxConcurrentRequests:(NSInteger)aVal {
	[self.queue setMaxConcurrentOperationCount:aVal];
}

- (void)setMaxLongConcurrentRequests:(NSInteger)maxLongConcurrentRequests{
    [self.longOperationQueue setMaxConcurrentOperationCount:maxLongConcurrentRequests];
}

- (void)enqueueRequest:(DAVBaseRequest *)aRequest {
	NSParameterAssert(aRequest != nil);
	
	aRequest.credentials = _credentials;
	aRequest.rootURL = _rootURL;
	aRequest.allowUntrustedCertificate = _allowUntrustedCertificate;
    
	if (aRequest.isLongRequest){
        [self.longOperationQueue addOperation:aRequest];
    }else{
        [self.queue addOperation:aRequest];
    }
}

- (void)cancelRequests {
	[self.queue cancelAllOperations];
}

- (void)cancelLongRequests {
    [self.longOperationQueue cancelAllOperations];
}

- (void)resetCredentialsCache {
	// reset the credentials cache...
	NSDictionary *credentialsDict = [[NSURLCredentialStorage sharedCredentialStorage] allCredentials];
	
	if ([credentialsDict count] > 0) {
		// the credentialsDict has NSURLProtectionSpace objs as keys and dicts of userName => NSURLCredential
		NSEnumerator *protectionSpaceEnumerator = [credentialsDict keyEnumerator];
		id urlProtectionSpace;
		
		// iterate over all NSURLProtectionSpaces
		while ((urlProtectionSpace = [protectionSpaceEnumerator nextObject])) {
			NSEnumerator *userNameEnumerator = [[credentialsDict objectForKey:urlProtectionSpace] keyEnumerator];
			id userName;
			
			// iterate over all usernames for this protection space, which are the keys for the actual NSURLCredentials
			while ((userName = [userNameEnumerator nextObject])) {
				NSURLCredential *cred = [[credentialsDict objectForKey:urlProtectionSpace] objectForKey:userName];
				
				[[NSURLCredentialStorage sharedCredentialStorage] removeCredential:cred
																forProtectionSpace:urlProtectionSpace];
			}
		}
	}
}

- (void)dealloc {
    if (_queue){
        [_queue removeObserver:self forKeyPath:@"operationCount"];
    }
    if (_longOperationQueue){
        [_longOperationQueue removeObserver:self forKeyPath:@"operationCount"];
    }
}

@end
