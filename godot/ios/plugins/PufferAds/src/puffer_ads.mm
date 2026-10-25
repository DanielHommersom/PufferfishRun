#include "puffer_ads.h"

#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <UIKit/UIKit.h>
#import <UserMessagingPlatform/UserMessagingPlatform.h>

#include "core/config/engine.h"

PufferAds *PufferAds::instance = nullptr;

static String to_godot(NSString *s) {
	return s ? String::utf8([s UTF8String]) : String();
}

static NSArray<NSString *> *to_ns(const PackedStringArray &arr) {
	NSMutableArray *out = [NSMutableArray arrayWithCapacity:arr.size()];
	for (int i = 0; i < arr.size(); i++) {
		[out addObject:[NSString stringWithUTF8String:arr[i].utf8().get_data()]];
	}
	return out;
}

static UIViewController *root_vc() {
	for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
		if ([scene isKindOfClass:UIWindowScene.class]) {
			for (UIWindow *w in ((UIWindowScene *)scene).windows) {
				if (w.isKeyWindow) {
					return w.rootViewController;
				}
			}
		}
	}
	return nil;
}

static void emit_main(const StringName &sig, const Variant &a = Variant(), bool has_arg = false) {
	dispatch_async(dispatch_get_main_queue(), ^{
		PufferAds *ads = PufferAds::get_singleton();
		if (!ads) {
			return;
		}
		if (has_arg) {
			ads->emit_signal(sig, a);
		} else {
			ads->emit_signal(sig);
		}
	});
}

// ── Interstitial delegate ───────────────────────────────────────────

@interface PufferInterstitialDelegate : NSObject <GADFullScreenContentDelegate>
@property(nonatomic, strong) GADInterstitialAd *ad;
@end

@implementation PufferInterstitialDelegate
- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
	self.ad = nil;
	emit_main("interstitial_dismissed");
}
- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
	self.ad = nil;
	emit_main("interstitial_failed_to_show", to_godot(error.localizedDescription), true);
}
@end

static PufferInterstitialDelegate *interstitial_delegate = nil;

// ── Rewarded delegate ───────────────────────────────────────────────

@interface PufferRewardedDelegate : NSObject <GADFullScreenContentDelegate>
@property(nonatomic, strong) GADRewardedAd *ad;
@end

@implementation PufferRewardedDelegate
- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
	self.ad = nil;
	emit_main("rewarded_dismissed");
}
- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
	self.ad = nil;
	emit_main("rewarded_failed_to_show", to_godot(error.localizedDescription), true);
}
@end

static PufferRewardedDelegate *rewarded_delegate = nil;

// ── PufferAds ───────────────────────────────────────────────────────

void PufferAds::_bind_methods() {
	ClassDB::bind_method(D_METHOD("request_consent", "debug_eea", "test_device_ids"), &PufferAds::request_consent);
	ClassDB::bind_method(D_METHOD("request_tracking_authorization"), &PufferAds::request_tracking_authorization);
	ClassDB::bind_method(D_METHOD("tracking_status"), &PufferAds::tracking_status);
	ClassDB::bind_method(D_METHOD("initialize", "test_device_ids"), &PufferAds::initialize);
	ClassDB::bind_method(D_METHOD("load_interstitial", "unit_id"), &PufferAds::load_interstitial);
	ClassDB::bind_method(D_METHOD("show_interstitial"), &PufferAds::show_interstitial);
	ClassDB::bind_method(D_METHOD("load_rewarded", "unit_id"), &PufferAds::load_rewarded);
	ClassDB::bind_method(D_METHOD("show_rewarded"), &PufferAds::show_rewarded);
	ClassDB::bind_method(D_METHOD("is_privacy_options_required"), &PufferAds::is_privacy_options_required);
	ClassDB::bind_method(D_METHOD("show_privacy_options"), &PufferAds::show_privacy_options);

	ADD_SIGNAL(MethodInfo("consent_finished", PropertyInfo(Variant::BOOL, "can_request_ads")));
	ADD_SIGNAL(MethodInfo("tracking_finished", PropertyInfo(Variant::INT, "status")));
	ADD_SIGNAL(MethodInfo("initialized"));
	ADD_SIGNAL(MethodInfo("interstitial_loaded"));
	ADD_SIGNAL(MethodInfo("interstitial_failed_to_load", PropertyInfo(Variant::STRING, "message")));
	ADD_SIGNAL(MethodInfo("interstitial_dismissed"));
	ADD_SIGNAL(MethodInfo("interstitial_failed_to_show", PropertyInfo(Variant::STRING, "message")));
	ADD_SIGNAL(MethodInfo("rewarded_loaded"));
	ADD_SIGNAL(MethodInfo("rewarded_failed_to_load", PropertyInfo(Variant::STRING, "message")));
	ADD_SIGNAL(MethodInfo("rewarded_earned"));
	ADD_SIGNAL(MethodInfo("rewarded_dismissed"));
	ADD_SIGNAL(MethodInfo("rewarded_failed_to_show", PropertyInfo(Variant::STRING, "message")));
	ADD_SIGNAL(MethodInfo("privacy_options_closed"));
}

// UMP consent form (EEA/UK) before ATT — missing in the Swift build (B13).
void PufferAds::request_consent(bool debug_eea, PackedStringArray test_device_ids) {
	UMPRequestParameters *params = [[UMPRequestParameters alloc] init];
	if (debug_eea) {
		UMPDebugSettings *debug = [[UMPDebugSettings alloc] init];
		debug.testDeviceIdentifiers = to_ns(test_device_ids);
		debug.geography = UMPDebugGeographyEEA;
		params.debugSettings = debug;
	}
	[UMPConsentInformation.sharedInstance
			requestConsentInfoUpdateWithParameters:params
								 completionHandler:^(NSError *error) {
									 if (error) {
										 emit_main("consent_finished", UMPConsentInformation.sharedInstance.canRequestAds, true);
										 return;
									 }
									 [UMPConsentForm loadAndPresentIfRequiredFromViewController:root_vc()
																			  completionHandler:^(NSError *formError) {
																				  emit_main("consent_finished", UMPConsentInformation.sharedInstance.canRequestAds, true);
																			  }];
								 }];
}

// ATT prompt only when notDetermined; otherwise report the existing status straight away.
void PufferAds::request_tracking_authorization() {
	if (ATTrackingManager.trackingAuthorizationStatus != ATTrackingManagerAuthorizationStatusNotDetermined) {
		emit_main("tracking_finished", (int)ATTrackingManager.trackingAuthorizationStatus, true);
		return;
	}
	[ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
		emit_main("tracking_finished", (int)status, true);
	}];
}

// 0 notDetermined, 1 restricted, 2 denied, 3 authorized
int PufferAds::tracking_status() {
	return (int)ATTrackingManager.trackingAuthorizationStatus;
}

void PufferAds::initialize(PackedStringArray test_device_ids) {
	if (test_device_ids.size() > 0) {
		GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers = to_ns(test_device_ids);
	}
	[GADMobileAds.sharedInstance startWithCompletionHandler:^(GADInitializationStatus *status) {
		emit_main("initialized");
	}];
}

void PufferAds::load_interstitial(String unit_id) {
	NSString *uid = [NSString stringWithUTF8String:unit_id.utf8().get_data()];
	[GADInterstitialAd loadWithAdUnitID:uid
								request:[GADRequest request]
					  completionHandler:^(GADInterstitialAd *ad, NSError *error) {
						  if (error) {
							  emit_main("interstitial_failed_to_load", to_godot(error.localizedDescription), true);
							  return;
						  }
						  if (!interstitial_delegate) {
							  interstitial_delegate = [[PufferInterstitialDelegate alloc] init];
						  }
						  interstitial_delegate.ad = ad;
						  ad.fullScreenContentDelegate = interstitial_delegate;
						  emit_main("interstitial_loaded");
					  }];
}

void PufferAds::show_interstitial() {
	GADInterstitialAd *ad = interstitial_delegate ? interstitial_delegate.ad : nil;
	UIViewController *vc = root_vc();
	if (!ad || !vc) {
		emit_main("interstitial_failed_to_show", String("not loaded"), true);
		return;
	}
	[ad presentFromRootViewController:vc];
}

void PufferAds::load_rewarded(String unit_id) {
	NSString *uid = [NSString stringWithUTF8String:unit_id.utf8().get_data()];
	[GADRewardedAd loadWithAdUnitID:uid
							request:[GADRequest request]
				  completionHandler:^(GADRewardedAd *ad, NSError *error) {
					  if (error) {
						  emit_main("rewarded_failed_to_load", to_godot(error.localizedDescription), true);
						  return;
					  }
					  if (!rewarded_delegate) {
						  rewarded_delegate = [[PufferRewardedDelegate alloc] init];
					  }
					  rewarded_delegate.ad = ad;
					  ad.fullScreenContentDelegate = rewarded_delegate;
					  emit_main("rewarded_loaded");
				  }];
}

void PufferAds::show_rewarded() {
	GADRewardedAd *ad = rewarded_delegate ? rewarded_delegate.ad : nil;
	UIViewController *vc = root_vc();
	if (!ad || !vc) {
		emit_main("rewarded_failed_to_show", String("not loaded"), true);
		return;
	}
	[ad presentFromRootViewController:vc
			 userDidEarnRewardHandler:^{
				 emit_main("rewarded_earned");
			 }];
}

// Google requires an entry point to change consent when UMP says it's required (EEA/UK).
bool PufferAds::is_privacy_options_required() {
	return UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == UMPPrivacyOptionsRequirementStatusRequired;
}

void PufferAds::show_privacy_options() {
	[UMPConsentForm presentPrivacyOptionsFormFromViewController:root_vc()
											  completionHandler:^(NSError *error) {
												  emit_main("privacy_options_closed");
											  }];
}

PufferAds::PufferAds() {
	instance = this;
}

PufferAds::~PufferAds() {
	if (instance == this) {
		instance = nullptr;
	}
}

// ── LegacyDefaults ──────────────────────────────────────────────────

void LegacyDefaults::_bind_methods() {
	ClassDB::bind_method(D_METHOD("read_legacy_defaults"), &LegacyDefaults::read_legacy_defaults);
}

Dictionary LegacyDefaults::read_legacy_defaults() {
	Dictionary d;
	NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
	if ([defaults objectForKey:@"highScore"]) {
		d["highScore"] = (int)[defaults integerForKey:@"highScore"];
	}
	NSString *skin = [defaults stringForKey:@"selectedSkin"];
	if (skin) {
		d["selectedSkin"] = to_godot(skin);
	}
	if ([defaults objectForKey:@"isMuted"]) {
		d["isMuted"] = (bool)[defaults boolForKey:@"isMuted"];
	}
	return d;
}
