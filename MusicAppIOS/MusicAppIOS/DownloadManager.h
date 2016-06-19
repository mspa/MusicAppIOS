//
//  DownloadManager.h
//  MusicAppIOS
//
//  Created by Roman on 19/06/16.
//  Copyright © 2016 Roman. All rights reserved.
//

typedef NS_ENUM(NSUInteger, DMConnectionState) {
    DMConnectionStateCancel, //отменить загрузку
    DMConnectionStateContinue //продолжить загрузку
};

@protocol CDownloadManagerDelegate;

@interface CDownloadManager : NSObject

- (id)initWithDelegate:(id<CDownloadManagerDelegate>)delegate;
- (NSUInteger) downloadFromURL:(NSURL*)url;
- (NSUInteger) continueDonwloadFromURL:(NSURL*)url withBytes:(long long)bytes;

@end


@protocol CDownloadManagerDelegate <NSObject>
@optional

/**
 Cообщает, что пришел заголовок, содержащий дату date последнего изменения файла на сервере (может отсутствовать) и размер length файла;
 Если функция возвращает DMConnectionStateExist, то
 */
- (DMConnectionState)downloadManager:(CDownloadManager*)downloadManager didReceiveResponseByURL:(NSURL*)url ForFile:(NSString*)fileName containDate:(NSDate*)date andLength:(long long)length;

/**
 Сообщает о завершении загрузки fileName
 */
- (void)downloadManager:(CDownloadManager*)downloadManager didFinishDownloading:(NSString*)fileName;

/**
 Сообщает о новой порции данных data файла fileName
 */
- (void)downloadManager:(CDownloadManager*)downloadManager didReceiveData:(NSData*)data forFile:(NSString*)fileName;
@end