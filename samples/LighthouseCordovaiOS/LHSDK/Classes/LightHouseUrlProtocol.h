//
//  LightHouseUrlProtocol.h
//  HttpSSLClient
//
//  Created by Kyle Champlin on 5/6/15.
//  Copyright (c) 2015 BusyWait. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPSDK.h"

@interface LightHouseUrlProtocol : NSURLProtocol

@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSURLResponse *response;


@end
