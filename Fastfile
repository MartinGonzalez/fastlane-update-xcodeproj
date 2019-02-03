lane :test_update_xcodeproj do
  update_xcodeproj(
    verbose: true,
    xcodeproj_path: '/Users/martingonzalez/Desktop/martin-fastlane-test/builds/iOS/Unity-iPhone.xcodeproj',
    plist_path: '/Users/martingonzalez/Desktop/martin-fastlane-test/builds/iOS/Info.plist',
    entitlements_path: '/Users/martingonzalez/Desktop/martin-fastlane-test/builds/iOS/Unity-iPhone/game.entitlements',
    entitlements: {
      'aps-environment' => 'development'
    },
    plist: {
      ITSAppUsesNonExemptEncryption: false
    },
    capabilities: {
      push_notifications: false,
      in_app_purchases: false
    },
    build_settings: {
      IPHONEOS_DEPLOYMENT_TARGET: '9.0',
      ENABLE_BITCODE: false,
      CODE_SIGN_ENTITLEMENTS: 'Unity-iPhone/game.entitlements'
    },
    other_ldflags: [
      '-lsqlite3'
    ],
    frameworks: %w[
      StoreKit
      UIKit
    ]
  )
end
