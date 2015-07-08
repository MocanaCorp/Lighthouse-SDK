//
//  LightHouseUrlProtocol.m
//  HttpSSLClient
//
//  Created by Kyle Champlin on 5/6/15.
//  Copyright (c) 2015 BusyWait. All rights reserved.
//

#import "LightHouseUrlProtocol.h"

@interface LightHouseUrlProtocol () <NSURLConnectionDelegate>
@property (nonatomic, strong) NSURLConnection *connection;

@end


@implementation LightHouseUrlProtocol

//Stuff you gotta implement as a delegate to not crashy crash
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{

    static NSUInteger requestCount = 0;
    NSLog(@"Request #%u: URL = %@", requestCount++, request);
     
    if ([NSURLProtocol propertyForKey:@"MyURLProtocolHandledKey" inRequest:request]) {
        return NO;
    }
    
    if (request.URL.isFileURL || request.URL.isFileReferenceURL){
        return NO;
    }
     
    return YES;


}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

//end stuff you gotta implement to not crashy crash


- (void)startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:@"MyURLProtocolHandledKey" inRequest:newRequest];
     
    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];

    
    
}

- (void)stopLoading
{
    [self.connection cancel];
    self.connection = nil;
}


- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return YES;
}


-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
    self.connection = nil;
    
    
}

- (void) connection:(NSURLConnection*)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    

    NSURLCredential *credential = self.getMAPCredential;


    
    //If there is a MAP User Certificate send that to the challenge
    if(credential){
        
        
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        
        NSLog(@"SENT CERTIFICATE TO CHALLENGE");
        
        
    }
    
    //respond to the challenge without a credential if we can't source the certificate from MAP
    //
    else {
        NSLog(@"No MAP CERT SENT");
        [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge ];
    }
    
    
}


//OLD SKOOL METHOD - INCLUDED FOR LEGACY SUPPORT
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    
    NSLog(@"Did recieve authentication challenge from app delegate!");
    NSURLCredential *credential = self.getMAPCredential;
    
    if(credential){
        
        
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        
        NSLog(@"SENT CERTIFICATE TO CHALLENGE");
        
    }
    
    else {
        NSLog(@"NO CERTIFICATE WAS SENT");
        [[challenge sender] useCredential:nil forAuthenticationChallenge:challenge];
    }
    
}

- (void)connection:(NSURLConnection*) connection didReceiveData:(NSData *)data
{
    
    //if the connection is also receiving data, then start saving that to the previous object "webdata"
    if(data){
        
        [self.client URLProtocol:self didLoadData:data];
        [self.mutableData appendData: data];
        
        
    };
    
    //if there is no data, display a message
    if(!data){
        NSLog(@"#################################");
        NSLog(@"No Data In The Response!");
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Web Response"
                                   message:@"No Response from Server"
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        // Display the Hello World Message
        [errorAlert show];
        
    };
    
    
    
}

- (void)connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *)response
{
    
    NSLog(@"Talking to lighthouse subclass");
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    self.response = response;
    self.mutableData  = [[NSMutableData alloc] init];
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog([NSString stringWithFormat:@"Did recieve error: %@", [error localizedDescription]]);
    NSLog([NSString stringWithFormat:@"%@", [error userInfo]]);
    [self.client URLProtocol:self didFailWithError:error];
    self.connection = nil;
}


- (NSURLCredential *) getMAPCredential;
{
    
    //KCHAMP
    SecIdentityRef myIdentity = MAP_getUserIdentityCertificate();
    BOOL hasCertificate = MAP_hasUserIdentityCertificate();
    NSLog(@"HAS_CERTIFICATE = %i", hasCertificate);
    NSLog(@"CERTIFICATE PTR = %p", myIdentity);
    
    
    NSLog(@"#################################");
    
    NSLog(@"Creating SecCertificateRef Object");
    
    if (hasCertificate){
        
        SecCertificateRef myCertificate;
        SecIdentityCopyCertificate(myIdentity, &myCertificate);
        const void *certs[] = { myCertificate };
        CFArrayRef certsArray = CFArrayCreate(NULL, certs, 1, NULL);
        
        NSLog(@"#################################");
        
        NSLog(@"Creating Credential Object");
        
        NSURLCredential *credential = [NSURLCredential credentialWithIdentity:myIdentity certificates:(__bridge NSArray*)certsArray persistence:NSURLCredentialPersistenceForSession];
        
        return credential;
    }
    
    else {
        
        
        return nil;
        
    }
    
    
}


OSStatus extractIdentityAndTrust(CFDataRef inP12data, SecIdentityRef *identity, SecTrustRef *trust)
{
    OSStatus securityError = errSecSuccess;
    
    CFStringRef password = CFSTR("userA");
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };
    
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import(inP12data, options, &items);
    
    if (securityError == 0) {
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex(items, 0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemIdentity);
        *identity = (SecIdentityRef)tempIdentity;
        const void *tempTrust = NULL;
        tempTrust = CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemTrust);
        *trust = (SecTrustRef)tempTrust;
    }
    
    if (options) {
        CFRelease(options);
    }
    
    return securityError;
}




@end
