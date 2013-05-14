//
//  DAVRequests.m
//  DAVKit
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import <Foundation/NSStream.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSException.h>
#import <Foundation/NSData.h>
#import "DAVRequests.h"

#import "DAVListingParser.h"
#import "DAVRequest+Private.h"

@implementation DAVCopyRequest

@synthesize destinationPath = _destinationPath;
@synthesize overwrite = _overwrite;

- (NSString *)method {
	return @"COPY";
}

- (NSURLRequest *)request {
	NSParameterAssert(_destinationPath != nil);
	
	NSURL *dp = [self concatenatedURLWithPath:_destinationPath];
	
	NSMutableURLRequest *req = [self newRequestWithPath:self.path
												 method:[self method]];
	
	[req setValue:[dp absoluteString] forHTTPHeaderField:@"Destination"];
	
	if (_overwrite)
		[req setValue:@"T" forHTTPHeaderField:@"Overwrite"];
	else
		[req setValue:@"F" forHTTPHeaderField:@"Overwrite"];
	
	return req;
}

@end


@implementation DAVDeleteRequest

- (NSURLRequest *)request {
	return [self newRequestWithPath:self.path method:@"DELETE"];
}

@end


@implementation DAVGetRequest

@synthesize targetFile=_targetFile;

- (NSURLRequest *)request {
	NSFileManager *fileMgr=[NSFileManager defaultManager];
	[fileMgr createFileAtPath:_targetFile contents:nil attributes:nil];
	_fileHandle=[NSFileHandle fileHandleForWritingAtPath:_targetFile];
	if (!_fileHandle){
		return nil;
	}
	return [self newRequestWithPath:self.path method:@"GET"];
}

- (id)resultForData:(NSData *)data {
	[_fileHandle closeFile];
	return data;
}

- (BOOL)dataReceived:(NSData *)data{
	[_fileHandle writeData:data];
	return YES;
}
@end


@implementation DAVListingRequest

@synthesize depth = _depth;

- (id)initWithPath:(NSString *)aPath {
	if (![aPath hasSuffix:@"/"]){
		aPath=[NSString stringWithFormat:@"%@%@",aPath,@"/"];
	}
	NSLog(@"%@",aPath);
	self = [super initWithPath:aPath];
	if (self) {
		_depth = 1;
	}
	return self;
}

- (NSURLRequest *)request {
	NSMutableURLRequest *req = [self newRequestWithPath:self.path method:@"PROPFIND"];
	NSLog(@"%@: %@",req, req.HTTPMethod);
	
	if (_depth > 1) {
		[req setValue:@"infinity" forHTTPHeaderField:@"Depth"];
	}
	else {
		[req setValue:[NSString stringWithFormat:@"%d", _depth] forHTTPHeaderField:@"Depth"];
	}
	
	[req setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
	
	NSString *xml = @"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
					@"<D:propfind xmlns:D=\"DAV:\"><D:allprop/></D:propfind>";
	
	[req setHTTPBody:[xml dataUsingEncoding:NSUTF8StringEncoding]];
	
	return req;
}

- (id)resultForData:(NSData *)data {
	DAVListingParser *p = [[DAVListingParser alloc] initWithData:data];
	
	NSError *error = nil;
	NSArray *items = [p parse:&error];
	
	if (error) {
		#ifdef DEBUG
			NSLog(@"XML Parse error: %@", error);
		#endif
	}
	
	return items;
}

@end


@implementation DAVMakeCollectionRequest

- (NSURLRequest *)request {
	return [self newRequestWithPath:self.path method:@"MKCOL"];
}

@end


@implementation DAVMoveRequest

- (NSString *)method {
	return @"MOVE";
}

@end


@implementation DAVPutRequest

- (id)initWithPath:(NSString *)path {
	if ((self = [super initWithPath:path])) {
		self.dataMIMEType = @"application/octet-stream";
	}
	return self;
}

@synthesize data = _pdata;
@synthesize dataMIMEType = _MIMEType;
@synthesize sourceFile=_sourceFile;

- (NSURLRequest *)request {
	NSParameterAssert(_pdata != nil && _sourceFile!=nil);
	NSMutableURLRequest *req;
	if (_pdata){
		NSString *len = [NSString stringWithFormat:@"%d", [_pdata length]];
		req = [self newRequestWithPath:self.path method:@"PUT"];
		[req setValue:[self dataMIMEType] forHTTPHeaderField:@"Content-Type"];
		[req setValue:len forHTTPHeaderField:@"Content-Length"];
		[req setHTTPBody:_pdata];
	}else{
		NSFileManager *fileMgr=[NSFileManager defaultManager];
		NSError *error=nil;
		NSDictionary *attr=[fileMgr attributesOfItemAtPath:_sourceFile error:&error];
		if (error){
			return nil;	
		}
		NSString *len=[NSString stringWithFormat:@"%lld", attr.fileSize];
		req = [self newRequestWithPath:self.path method:@"PUT"];
		[req setValue:[self dataMIMEType] forHTTPHeaderField:@"Content-Type"];
		[req setValue:len forHTTPHeaderField:@"Content-Length"];
		NSInputStream *input=[NSInputStream inputStreamWithFileAtPath:_sourceFile];
		[req setHTTPBodyStream:input];
	}
	
	return req;
}

@end
