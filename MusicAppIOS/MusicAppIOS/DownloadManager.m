//
//  DownloadManager.m
//  MusicAppIOS
//
//  Created by Roman on 19/06/16.
//  Copyright © 2016 Roman. All rights reserved.
//

#import "DownloadManager.h"

@interface CDownloadManager () <NSURLSessionDataDelegate>

@property (nonatomic, weak) id <CDownloadManagerDelegate> delegate;
@end

@implementation CDownloadManager {
    struct {
        unsigned
        didReceiveResponse : 1,
        didReceiveData : 1,
        didFinishData : 1;
    } delegateFlags;
    NSURLSession *defaultSession;
    NSMutableArray *tasks;
}

- (id)initWithDelegate:(id<CDownloadManagerDelegate>)delegate {
    if (self = [super init]) {
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        tasks = [NSMutableArray array];
        _delegate = delegate;
        delegateFlags.didReceiveResponse = [_delegate respondsToSelector:@selector(downloadManager:didReceiveResponseByURL:ForFile:containDate:andLength:)];
        delegateFlags.didReceiveData = [_delegate respondsToSelector:@selector(downloadManager:didReceiveData:forFile:)];
        delegateFlags.didFinishData = [_delegate respondsToSelector:@selector(downloadManager:didFinishDownloading:)];
    }
    
    return self;
}

- (NSUInteger)downloadFromURL:(NSURL *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request];
    [task resume];
    return [task taskIdentifier];
}

- (NSUInteger)continueDonwloadFromURL:(NSURL *)url withBytes:(long long)bytes
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", bytes] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request];
    [task resume];
    return [task taskIdentifier];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    DMConnectionState state = DMConnectionStateCancel;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSString * dateString = [NSString stringWithFormat:@"%@",
                                 [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Last-Modified"]];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
        NSDate *date = [formatter dateFromString:dateString];
        long long size = [response expectedContentLength];
        if (size == NSURLResponseUnknownLength)
            size = 0;
        
        //если задача только началась
        if (delegateFlags.didReceiveResponse) {
            state = [_delegate downloadManager:self didReceiveResponseByURL:[[dataTask currentRequest] URL] ForFile:[[dataTask response] suggestedFilename] containDate:date andLength:size];
        }
        
    }
    
    switch (state) {
        case DMConnectionStateCancel:
            completionHandler(NSURLSessionResponseCancel);
            break;
        case DMConnectionStateContinue:
            completionHandler(NSURLSessionResponseAllow);
            break;
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (delegateFlags.didReceiveData) {
        [_delegate downloadManager:self didReceiveData:data forFile:[[dataTask response] suggestedFilename]];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"Download %@ completed with eror %@", [[task response] suggestedFilename], [error localizedDescription]);
    } else {
        if (delegateFlags.didFinishData) {
            [_delegate downloadManager:self didFinishDownloading:[[task response] suggestedFilename]];
        }
    }
}
@end
