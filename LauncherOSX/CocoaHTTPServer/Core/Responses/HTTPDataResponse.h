#import <Foundation/Foundation.h>
#import "HTTPResponse.h"


@interface HTTPDataResponse : NSObject <HTTPResponse>
{
	NSUInteger offset;
	NSData *data;
    NSString *contentType;
}

- (id)initWithData:(NSData *)dataParam;
- (id)initWithData:(NSData *)dataParam contentType:(NSString *)contentTypeParam;

@end
