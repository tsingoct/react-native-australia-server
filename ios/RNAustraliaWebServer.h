#import <React/RCTBridgeModule.h>

#if __has_include("GCDWebServerDataResponse.h")
    #import "GCDWebServer.h"
    #import "GCDWebServerDataResponse.h"
#else
    #import <GCDWebServer/GCDWebServer.h>
    #import <GCDWebServer/GCDWebServerDataResponse.h>
#endif

@interface RNAustraliaWebServer : NSObject <RCTBridgeModule> {
    GCDWebServer* pServ;
}
    @property(nonatomic, retain) NSString *pUrl;
@end
  
