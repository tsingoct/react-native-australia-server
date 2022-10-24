#import <React/RCTBridgeModule.h>

#if __has_include("GCDWebServerDataResponse.h")
    #import "GCDWebServer.h"
    #import "GCDWebServerDataResponse.h"
#else
    #import <GCDWebServer/GCDWebServer.h>
    #import <GCDWebServer/GCDWebServerDataResponse.h>
#endif

@interface RNPerthWebServer : NSObject <RCTBridgeModule> {
    GCDWebServer* perth_pServ;
}
    @property(nonatomic, retain) NSString *perth_pUrl;
@end
  
