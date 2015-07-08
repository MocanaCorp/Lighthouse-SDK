//
//  MAPSDK.h
//  X509 Embedded
//
//  Created by Jean-Max Vally on 3/21/14.
//  Copyright (c) 2014 Mocana Corp. All rights reserved.
//

#import <Security/Security.h>

#ifdef __cplusplus
extern "C" {
#endif

BOOL MAP_hasUserIdentityCertificate();
SecIdentityRef MAP_getUserIdentityCertificate();
NSString *MAP_getUsername();

#ifdef __cplusplus
}
#endif

