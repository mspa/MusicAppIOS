//
//  PlayerViewController.m
//  MusicAppIOS
//
//  Created by Roman on 19/06/16.
//  Copyright © 2016 Roman. All rights reserved.
//

#import "PlayerViewController.h"
#import "MusicTrack.h"
#import "TrackInfoTableViewCell.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayerViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) AVAudioPlayer *player;
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation PlayerViewController {
    NSMutableDictionary *info;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    info = [[NSMutableDictionary alloc] init];
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[self musicTrack] getPath]]];
    for (AVMetadataItem *metadataItem in asset.commonMetadata) {
        if ([metadataItem.commonKey isEqualToString:@"title"]) {
            [info setObject:(NSString *)[metadataItem value] forKey:@"title"];
        } else if ([metadataItem.commonKey isEqualToString:@"artist"]) {
            [info setObject:(NSString *)[metadataItem value] forKey:@"artist"];
        } else if ([metadataItem.commonKey isEqualToString:@"albumName"]) {
            [info setObject:(NSString *)[metadataItem value] forKey:@"albumName"];
        } else if ([metadataItem.commonKey isEqualToString:@"artwork"]){
            self.image.image = [UIImage imageWithData:(NSData *)metadataItem.value];
        }
    }
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[self musicTrack] getPath]] error:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [_player stop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickedOnPlayButton:(id)sender {
    if (_player.isPlaying) {
        [self.player pause];
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    } else {
        [self.player play];
        [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[info allKeys] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CTrackInfoTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"trackInfoTableViewCell"];
    if (!cell) {
        cell = [[CTrackInfoTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"trackInfoTableViewCell"];
    }
    NSArray *keys = [info allKeys];
    cell.titleLabel.text = keys[indexPath.row];
    cell.valueLabel.text = [info objectForKey:keys[indexPath.row]];
    return cell;
}

@end
