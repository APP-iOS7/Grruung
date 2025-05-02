//
//  GrruungApp.swift
//  Grruung
//
//  Created by NoelMacMini on 4/30/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck
import FirebaseAppCheckInterop // App Attest Provider 사용을 위해 필요 (경우에 따라 필요)

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase 초기화 전에 App Check 제공자 설정
        let providerFactory = GRAppCheckProviderFactory() 
        
        AppCheck.setAppCheckProviderFactory(providerFactory) // 설정한 제공자 팩토리로 App Check 설정
        
        FirebaseApp.configure()
        
        print("Firebase와 App Check 초기화 완료")
        return true
    }
}

class GRAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    // 디버그 빌드에서는 DebugProvider를, 릴리스 빌드에서는 AppAttestProvider를 사용하도록 설정
    #if targetEnvironment(simulator)
        // 시뮬레이터에서는 DebugProvider 사용
        return AppCheckDebugProvider(app: app)
    #else
        // 실제 기기에서는 App Attest Provider 사용
        return AppAttestProvider(app: app)
    #endif
    }
}

@main
struct GrruungApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
