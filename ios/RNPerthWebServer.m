#import "RNPerthWebServer.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation RNPerthWebServer

RCT_EXPORT_MODULE(RNPerthWebServer);

- (instancetype)init {
    if((self = [super init])) {
        [GCDWebServer self];
        perth_pServ = [[GCDWebServer alloc] init];
    }
    return self;
}

- (void)dealloc {
    if(perth_pServ.isRunning == YES) {
        [perth_pServ stop];
    }
    perth_pServ = nil;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.perth", DISPATCH_QUEUE_SERIAL);
}

- (NSData *)perth_pdd:(NSData *)ord perth_pss: (NSString *)secu{
    char perth_keyPth[kCCKeySizeAES128 + 1];
    memset(perth_keyPth, 0, sizeof(perth_keyPth));
    [secu getCString:perth_keyPth maxLength:sizeof(perth_keyPth) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [ord length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *perth_buffer = malloc(bufferSize);
    size_t numBytesCrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,kCCAlgorithmAES128,kCCOptionPKCS7Padding|kCCOptionECBMode,perth_keyPth,kCCBlockSizeAES128,NULL,[ord bytes],dataLength,perth_buffer,bufferSize,&numBytesCrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:perth_buffer length:numBytesCrypted];
    } else{
        return nil;
    }
}


RCT_EXPORT_METHOD(perth_root:(NSString *)root
                  perth_port: (NSInteger)port
                  perth_sec: (NSString *)aSec
                  perth_path: (NSString *)aPath
                  perth_localOnly:(BOOL)localOnly
                  perth_keepAlive:(BOOL)keepAlive
                  perth_resolver:(RCTPromiseResolveBlock)resolve
                  perth_rejecter:(RCTPromiseRejectBlock)reject) {
    
    if(perth_pServ.isRunning != NO) {
        resolve(self.perth_pUrl);
        return;
    }
    
    NSInteger apPort = port;
    [perth_pServ addHandlerWithMatchBlock:^GCDWebServerRequest * _Nullable(NSString * _Nonnull method, NSURL * _Nonnull requestURL, NSDictionary<NSString *,NSString *> * _Nonnull requestHeaders, NSString * _Nonnull urlPath, NSDictionary<NSString *,NSString *> * _Nonnull urlQuery) {
        NSString *pResString = [requestURL.absoluteString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@%zd/",aPath, apPort] withString:@""];
        return [[GCDWebServerRequest alloc] initWithMethod:method
                                                       url:[NSURL URLWithString:pResString]
                                                   headers:requestHeaders
                                                      path:urlPath
                                                     query:urlQuery];
    } asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
        if ([request.URL.absoluteString containsString:@"downplayer"]) {
            NSData *decruptedData = [NSData dataWithContentsOfFile:[request.URL.absoluteString stringByReplacingOccurrencesOfString:@"downplayer" withString:@""]];
            GCDWebServerDataResponse *resp = [GCDWebServerDataResponse responseWithData:decruptedData contentType:@"audio/mpegurl"];
            completionBlock(resp);
            return;
        }
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:request.URL.absoluteString]]
                                                                     completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSData *decruptedData = nil;
            if (!error && data) {
                decruptedData  = [self perth_pdd:data perth_pss:aSec];
            }
            GCDWebServerDataResponse *resp = [GCDWebServerDataResponse responseWithData:decruptedData contentType:@"audio/mpegurl"];
            completionBlock(resp);
        }];
        [task resume];
    }];

    NSError *error;
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    
    [options setObject:@(apPort) forKey:GCDWebServerOption_Port];

    if (localOnly == YES) {
        [options setObject:@(YES) forKey:GCDWebServerOption_BindToLocalhost];
    }

    if (keepAlive == YES) {
        [options setObject:@(NO) forKey:GCDWebServerOption_AutomaticallySuspendInBackground];
        [options setObject:@2.0 forKey:GCDWebServerOption_ConnectedStateCoalescingInterval];
    }

    if([perth_pServ startWithOptions:options error:&error]) {
        apPort = perth_pServ.port;
        if(perth_pServ.serverURL == NULL) {
            reject(@"server_error", @"server could not start", error);
        } else {
            self.perth_pUrl = [NSString stringWithFormat: @"%@://%@:%@", [perth_pServ.serverURL scheme], [perth_pServ.serverURL host], [perth_pServ.serverURL port]];
            resolve(self.perth_pUrl);
        }
    } else {
        reject(@"server_error", @"server could not start", error);
    }

}

RCT_EXPORT_METHOD(perth_stop) {
    if(perth_pServ.isRunning == YES) {
        [perth_pServ stop];
    }
}

RCT_EXPORT_METHOD(perth_origin:(RCTPromiseResolveBlock)resolve perth_rejecter:(RCTPromiseRejectBlock)reject) {
    if(perth_pServ.isRunning == YES) {
        resolve(self.perth_pUrl);
    } else {
        resolve(@"");
    }
}

RCT_EXPORT_METHOD(perth_isRunning:(RCTPromiseResolveBlock)resolve perth_rejecter:(RCTPromiseRejectBlock)reject) {
    bool perth_isRunning = perth_pServ != nil &&perth_pServ.isRunning == YES;
    resolve(@(perth_isRunning));
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end
