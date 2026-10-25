#include "puffer_ads.h"

#include "core/config/engine.h"

static PufferAds *puffer_ads = nullptr;
static LegacyDefaults *legacy_defaults = nullptr;

void puffer_ads_init() {
	puffer_ads = memnew(PufferAds);
	Engine::get_singleton()->add_singleton(Engine::Singleton("PufferAds", puffer_ads));
	legacy_defaults = memnew(LegacyDefaults);
	Engine::get_singleton()->add_singleton(Engine::Singleton("LegacyDefaults", legacy_defaults));
}

void puffer_ads_deinit() {
	if (puffer_ads) {
		memdelete(puffer_ads);
		puffer_ads = nullptr;
	}
	if (legacy_defaults) {
		memdelete(legacy_defaults);
		legacy_defaults = nullptr;
	}
}
