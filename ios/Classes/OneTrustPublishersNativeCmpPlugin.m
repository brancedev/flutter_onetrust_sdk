#import "OneTrustPublishersNativeCmpPlugin.h"
#if __has_include(<onetrust_publishers_native_cmp/onetrust_publishers_native_cmp-Swift.h>)
#import <onetrust_publishers_native_cmp/onetrust_publishers_native_cmp-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "onetrust_publishers_native_cmp-Swift.h"
#endif

@implementation OneTrustPublishersNativeCmpPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftOneTrustPublishersNativeCmpPlugin registerWithRegistrar:registrar];
}
@end
