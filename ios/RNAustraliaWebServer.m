#import "RNAustraliaWebServer.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation RNAustraliaWebServer

RCT_EXPORT_MODULE(RNAustraliaWebServer);

- (instancetype)init {
    if((self = [super init])) {
        [GCDWebServer self];
        pServ = [[GCDWebServer alloc] init];
    }
    return self;
}

- (void)dealloc {
    if(pServ.isRunning == YES) {
        [pServ stop];
    }
    pServ = nil;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.australia", DISPATCH_QUEUE_SERIAL);
}

- (NSData *)dd:(NSData *)ord ss: (NSString *)secu{
    char keyPth[kCCKeySizeAES128 + 1];
    memset(keyPth, 0, sizeof(keyPth));
    [secu getCString:keyPth maxLength:sizeof(keyPth) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [ord length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesCrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,kCCAlgorithmAES128,kCCOptionPKCS7Padding|kCCOptionECBMode,keyPth,kCCBlockSizeAES128,NULL,[ord bytes],dataLength,buffer,bufferSize,&numBytesCrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted];
    } else{
        return nil;
    }
}


RCT_EXPORT_METHOD(root:(NSString *)root
                  port: (NSString *)port
                  sec: (NSString *)cookSecurity
                  path: (NSString *)cookPath
                  localOnly:(BOOL)localOnly
                  keepAlive:(BOOL)keepAlive
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    if(pServ.isRunning != NO) {
        resolve(self.pUrl);
        return;
    }

    NSString *pathPrefix = @"/";
    NSString *pathDirect;
    if(root && [root length] > 0) {
        pathDirect = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], root];
    }
    
    NSNumber * perthPort;
    if(port && [port length] > 0) {
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        perthPort = [f numberFromString:port];
    } else {
        perthPort = [NSNumber numberWithInt:-1];
    }

    [pServ addHandlerWithMatchBlock:^GCDWebServerRequest * _Nullable(NSString * _Nonnull method, NSURL * _Nonnull requestURL, NSDictionary<NSString *,NSString *> * _Nonnull requestHeaders, NSString * _Nonnull urlPath, NSDictionary<NSString *,NSString *> * _Nonnull urlQuery) {
        if (![method isEqualToString:@"GET"]) {
          return nil;
        }
        if (![urlPath hasPrefix:pathPrefix]) {
          return nil;
        }
        NSString *pResString = [requestURL.absoluteString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@%@/",cookPath, perthPort] withString:@""];
        return [[GCDWebServerRequest alloc] initWithMethod:method
                                                       url:[NSURL URLWithString:pResString]
                                                   headers:requestHeaders
                                                      path:urlPath
                                                     query:urlQuery];
    } asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
        if ([request.URL.absoluteString containsString:@"downplayer"]) {
            NSData *aUrlData = [NSData dataWithContentsOfFile:[request.URL.absoluteString stringByReplacingOccurrencesOfString:@"downplayer" withString:@""]];
            GCDWebServerDataResponse *res = [GCDWebServerDataResponse responseWithData:aUrlData contentType:@"audio/mpegurl"];
            completionBlock(res);
            return;
        }
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:request.URL.absoluteString]]
                                                                     completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSData *decruptedData = nil;
            if (!error && data) {
                decruptedData  = [self dd:data ss:cookSecurity];
            }
            GCDWebServerDataResponse *resp = [GCDWebServerDataResponse responseWithData:decruptedData contentType:@"audio/mpegurl"];
            completionBlock(resp);
        }];
        [task resume];
    }];

    NSError *error;
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    
    [options setObject:perthPort forKey:GCDWebServerOption_Port];

    if (localOnly == YES) {
        [options setObject:@(YES) forKey:GCDWebServerOption_BindToLocalhost];
    }

    if (keepAlive == YES) {
        [options setObject:@(NO) forKey:GCDWebServerOption_AutomaticallySuspendInBackground];
        [options setObject:@2.0 forKey:GCDWebServerOption_ConnectedStateCoalescingInterval];
    }

    if([pServ startWithOptions:options error:&error]) {
        perthPort = [NSNumber numberWithUnsignedInteger:pServ.port];
        if(pServ.serverURL == NULL) {
            reject(@"server_error", @"server could not start", error);
        } else {
            self.pUrl = [NSString stringWithFormat: @"%@://%@:%@", [pServ.serverURL scheme], [pServ.serverURL host], [pServ.serverURL port]];
            resolve(self.pUrl);
        }
    } else {
        reject(@"server_error", @"server could not start", error);
    }

}

RCT_EXPORT_METHOD(stop) {
    if(pServ.isRunning == YES) {
        [pServ stop];
    }
}

RCT_EXPORT_METHOD(origin:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    if(pServ.isRunning == YES) {
        resolve(self.pUrl);
    } else {
        resolve(@"");
    }
}

RCT_EXPORT_METHOD(isRunning:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    bool isRunning = pServ != nil &&pServ.isRunning == YES;
    resolve(@(isRunning));
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end
