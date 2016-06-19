//
//  MusicTrack.m
//  MusicAppIOS
//
//  Created by Roman on 19/06/16.
//  Copyright © 2016 Roman. All rights reserved.
//

#import "MusicTrack.h"

@implementation MusicTrack

@synthesize name;

+ (NSString*) getDirectory {
    NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [documentPath stringByAppendingString:@"/music"];
}

- (NSString*) getPath {
    return [[MusicTrack getDirectory] stringByAppendingFormat:@"/%@", [self name]];
}
@end
