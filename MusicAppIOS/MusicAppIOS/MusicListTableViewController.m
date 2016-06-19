//
//  MusicListTableViewController.m
//  MusicAppIOS
//
//  Created by Roman on 19/06/16.
//  Copyright © 2016 Roman. All rights reserved.
//

#import "MusicListTableViewController.h"
#import "MusicTrack.h"
#import "MusicTrackViewCell.h"
#import "DownloadManager.h"
#import "PlayerViewController.h"

static NSString *PLAY_MUSIC_SEGUE_ID = @"playMusic";
static NSString *FILE_NAME_WITH_URLS = @"content.txt";

@interface MusicListTableViewController () <UITableViewDelegate, UITableViewDataSource, CDownloadManagerDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property CDownloadManager *downloadManager;
@property NSMutableDictionary* continueDownloads;

@end

@implementation MusicListTableViewController {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _downloadManager = [[CDownloadManager alloc] initWithDelegate:self];
    _continueDownloads = [[NSMutableDictionary alloc] init];
    [self loadListURLs];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) loadListURLs {
    NSLog(@"load playlist");
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    filePath = [filePath stringByAppendingFormat:@"/%@", FILE_NAME_WITH_URLS];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    [_downloadManager downloadFromURL:[NSURL URLWithString:@"https://www.dropbox.com/s/0m4lmwgt6sn5zto/content.txt?dl=1"]];
}

//начинает загрузку url, которые находятся в filePath
- (void) loadPlaylistFromFile:(NSString *)filePath {
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    for (NSString *line in [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
        [_downloadManager downloadFromURL:[NSURL URLWithString:line]];
    }
}

#pragma mark - UITableViewDelegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:PLAY_MUSIC_SEGUE_ID]) {
        PlayerViewController *playerVC = (PlayerViewController*)segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        playerVC.musicTrack = (MusicTrack *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    
    if ([self.fetchedResultsController sections].count > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        numberOfRows = [sectionInfo numberOfObjects];
    }
    
    return numberOfRows;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CMusicTrackViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"musicTrackViewCell"];
    if (!cell) {
        cell = [[CMusicTrackViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                          reuseIdentifier:@"musicTrackViewCell"];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(CMusicTrackViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    NSManagedObject* track = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.musicName.text = [track valueForKey:@"name"];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // задаем имя сущности
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"MusicTrack" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        // задаем и затем устанавливаем параметр сортировки
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
        aFetchedResultsController.delegate = self;
        self.fetchedResultsController = aFetchedResultsController;
    }
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(CMusicTrackViewCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}


#pragma mark - CDownloadManagerDelegate

- (DMConnectionState)downloadManager:(CDownloadManager *)downloadManager didReceiveResponseByURL:(NSURL *)url ForFile:(NSString *)fileName containDate:(NSDate *)date andLength:(long long)length {
    if ([fileName isEqualToString:FILE_NAME_WITH_URLS]) {
        return DMConnectionStateContinue;
    }
    if ([_continueDownloads[fileName]  isEqual: @YES]) {
        return DMConnectionStateContinue;
    }
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    filePath = [MusicTrack getDirectory];
    filePath = [filePath stringByAppendingFormat:@"/%@", fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return DMConnectionStateContinue;
    }
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSDate *fileDate = nil;
    [fileURL getResourceValue:&fileDate forKey:NSURLContentModificationDateKey error:nil];
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    
    //дата последнего изменения файла на диске меньше, чем на сервере
    if (date && fileDate && [date compare:fileDate] == NSOrderedDescending) {
        return DMConnectionStateContinue;
    }
    
    if (fileSize == length) {
        return DMConnectionStateCancel;
    }
    
    _continueDownloads[fileName] = @YES;
    //продолжаем старую загрузку
    [self.downloadManager continueDonwloadFromURL:url withBytes:fileSize];
    //и отменяем старую
    return DMConnectionStateCancel;
}

- (void)downloadManager:(CDownloadManager *)downloadManager didReceiveData:(NSData *)data forFile:(NSString *)fileName {
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if (![fileName isEqualToString:FILE_NAME_WITH_URLS]) {
        filePath = [MusicTrack getDirectory];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:NO attributes:nil error:nil];
        }
    }
    filePath = [filePath stringByAppendingFormat:@"/%@", fileName];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fileHandle) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:data attributes:nil];
    } else {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    }
}

- (void)downloadManager:(CDownloadManager *)downloadManager didFinishDownloading:(NSString *)fileName {
    NSString *directoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if ([fileName isEqualToString:FILE_NAME_WITH_URLS]) {
        [self loadPlaylistFromFile:[directoryPath stringByAppendingFormat:@"/%@", fileName]];
    } else {
        NSManagedObject *track = [NSEntityDescription insertNewObjectForEntityForName:@"MusicTrack"
                                                               inManagedObjectContext:self.managedObjectContext];
        [track setValue:fileName forKey:@"name"];
        NSError *error = nil;
        if (![track.managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
