//
//  MAPSDK.m
//  X509 Embedded
//
//  Created by Jean-Max Vally on 3/21/14.
//  Copyright (c) 2014 Mocana Corp. All rights reserved.
//

#import "MAPSDK.h"
#import <Foundation/NSDictionary.h>
#import "MAPSDK.h"

// BEGIN CUSTOM CODE
//
//Change the following to match the certificate filename and password
//when testing the application with an embedded certificate (part of the
//application bundle

static NSString * const kCertificateFileName      = @"kchamplin_ejbca";
static NSString * const kCertificateFileExtension = @"p12";
static NSString * const kCertificatePassword      = @"abcd1234";
static NSString * const kUsername                 = @"sam-account-name";
//
// END CUSTOM CODE
//


@interface MAPSDK_CertificateProvider : NSObject
+(BOOL) hasUserIdentityCertificate;
+(SecIdentityRef) getUserIdentityCertificate;
+(NSString *) getUsername;
@end

@implementation MAPSDK_CertificateProvider

+(BOOL) hasUserIdentityCertificate
{
#ifdef DEBUG
    NSLog(@"MAPSDK_CertificateProvider:hasUserIdentityCertificate");
    NSString *path = [[NSBundle mainBundle] pathForResource:kCertificateFileName ofType:kCertificateFileExtension];
    return (path != nil);
#else
    return FALSE;
#endif
}

+(SecIdentityRef) getUserIdentityCertificate
{
#ifdef DEBUG
    NSLog(@"MAPSDK_CertificateProvider:getUserIdentityCertificate");
    NSString *path = [[NSBundle mainBundle] pathForResource:kCertificateFileName ofType:kCertificateFileExtension];
    if (path != nil)
    {
        NSLog(@"#################################");
        NSLog(@"Looking for data at %@",path);
        NSData *p12data = [NSData dataWithContentsOfFile:path];
        
        if (p12data != nil)
        {
            NSLog(@"#################################");
            NSLog(@"CERTIFICATE FOUND!");
            CFDataRef inP12data = (__bridge CFDataRef)p12data;
            CFStringRef password = (__bridge CFStringRef)kCertificatePassword;
            const void *keys[] = { kSecImportExportPassphrase };
            const void *values[] = { password };
            
            CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
            
            CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
            OSStatus securityError = SecPKCS12Import(inP12data, options, &items);
            if (securityError == 0 && CFArrayGetCount(items) > 0) {
                CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex(items, 0);
                SecIdentityRef identity = (SecIdentityRef)CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemIdentity);
                return identity;
            }
            
            if (options) {
                CFRelease(options);
            }
        }
    }
#endif
    return NULL;
}



+(NSString *) getUsername
{
#ifdef DEBUG
    return kUsername;
#else
    return nil;
#endif
}

@end



BOOL MAP_hasUserIdentityCertificate()
{
    NSLog(@"MAP_hasUserIdentityCertificate");
    return [ MAPSDK_CertificateProvider hasUserIdentityCertificate];
}

SecIdentityRef MAP_getUserIdentityCertificate()
{
    NSLog(@"MAP_getUserIdentityCertificate");
    return [MAPSDK_CertificateProvider getUserIdentityCertificate];
}

NSString *MAP_getUsername()
{
    NSLog(@"MAP_getUsername");
    return [MAPSDK_CertificateProvider getUsername];

}
