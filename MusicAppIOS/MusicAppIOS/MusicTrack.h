//
//  MusicTrack.h
//  MusicAppIOS
//
//  Created by Roman on 19/06/16.
//  Copyright © 2016 Roman. All rights reserved.
//

@interface MusicTrack : NSManagedObject

@property (nonatomic, strong) NSString *name;

+ (NSString*)getDirectory;
- (NSString*) getPath;

@end
