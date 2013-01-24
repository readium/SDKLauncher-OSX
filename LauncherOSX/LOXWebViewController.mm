//
//  LOXWebViewController.m
//  LauncherOSX
//
//  Created by Boris Schneiderman.
//  Copyright (c) 2012-2013 The Readium Foundation.
//
//  The Readium SDK is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "LOXWebViewController.h"
#import "LOXePubApi.h"

@implementation LOXWebViewController

- (void)displayUrl:(NSString *)url
{

}

- (void)displayHtml:(NSString *)html
{
    [[_webView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}

-(void)displayUrlPath:(NSString *)urlPath
{
    NSURL* fileURL = [NSURL fileURLWithPath:urlPath];
    NSURLRequest* request = [NSURLRequest requestWithURL:fileURL  ];
    [[_webView mainFrame] loadRequest:request];
}

- (void)clear
{
    [[_webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
}


- (NSURLRequest *)webView:(WebView *)sender
                 resource:(id)identifier
          willSendRequest:(NSURLRequest *)request
         redirectResponse:(NSURLResponse *)redirectResponse
           fromDataSource:(WebDataSource *)dataSource
{

    NSString *path = request.URL.path;

    [self.epubApi prepareResourceWithPath: path];

    return request;
}


@end
