#pragma once

#include "core/object/class_db.h"
#include "core/object/object.h"

// Godot singleton "PufferAds": UMP consent, ATT prompt, Google Mobile Ads start and one
// interstitial slot. All callbacks are emitted as signals on the main thread.
class PufferAds : public Object {
	GDCLASS(PufferAds, Object);

	static PufferAds *instance;

protected:
	static void _bind_methods();

public:
	static PufferAds *get_singleton() { return instance; }

	void request_consent(bool debug_eea, PackedStringArray test_device_ids);
	void request_tracking_authorization();
	int tracking_status();
	void initialize(PackedStringArray test_device_ids);
	void load_interstitial(String unit_id);
	void show_interstitial();
	void load_rewarded(String unit_id);
	void show_rewarded();
	bool is_privacy_options_required();
	void show_privacy_options();

	PufferAds();
	~PufferAds();
};

// Godot singleton "LegacyDefaults" (US-25): reads the Swift build's NSUserDefaults keys.
class LegacyDefaults : public Object {
	GDCLASS(LegacyDefaults, Object);

protected:
	static void _bind_methods();

public:
	Dictionary read_legacy_defaults();
};
