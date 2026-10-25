extends Node
## In-app purchases via RevenueCat (Godotx RevenueCat plugin, singleton "GodotxRevenueCat" —
## same setup as PopPulse). RevenueCat talks to StoreKit, validates receipts and tells us
## whether the `no_ads` entitlement is active.
##
## Only product: the non-consumable "Remove Ads" (turns interstitials off for good).
## The entitlement is re-checked on every launch, so Remove Ads survives reinstalls and new
## phones automatically; RESTORE PURCHASES does the same on demand.
##
## Without the plugin or API key: debug builds simulate the purchase (testable on a Mac);
## release builds report the store as unavailable.

signal purchase_finished(product_id: String, success: bool, message: String)
signal restore_finished(restored: int)
signal price_updated(product_id: String, price: String)

const SINGLETON := "GodotxRevenueCat"
## Public iOS SDK key from RevenueCat ▸ Project ▸ API keys (starts with "appl_"). Not a secret.
const IOS_API_KEY := "appl_MLyOlINBXevbkoOvqpIPgtPotLe"
const ENTITLEMENT := "no_ads"

var remove_ads_price := Constants.REMOVE_ADS_FALLBACK_PRICE
var _rc: Object


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton(SINGLETON) and IOS_API_KEY != "":
		_rc = Engine.get_singleton(SINGLETON)
		_rc.customer_info_changed.connect(_on_customer_info)
		_rc.purchase_result.connect(_on_purchase_result)
		_rc.products.connect(_on_products)
		_rc.restore_finished.connect(_on_restore_finished)
		_rc.initialize(IOS_API_KEY, "", OS.is_debug_build())
		_rc.fetch_products([Constants.REMOVE_ADS_PRODUCT_ID])
		if _rc.has_method("get_customer_info"):
			_rc.get_customer_info() # silent restore on every start (reinstall / new phone)
	elif Engine.has_singleton(SINGLETON):
		_log("RevenueCat plugin present but IOS_API_KEY is empty — purchases unavailable")
	else:
		_log("no RevenueCat plugin — purchases %s" % ("simulated" if OS.is_debug_build() else "unavailable"))


func is_available() -> bool:
	return _rc != null or OS.is_debug_build()


func buy_remove_ads() -> void:
	if SaveManager.ads_removed:
		purchase_finished.emit(Constants.REMOVE_ADS_PRODUCT_ID, true, "already owned")
		return
	if _rc:
		_rc.purchase(Constants.REMOVE_ADS_PRODUCT_ID)
	elif OS.is_debug_build():
		_log("simulating Remove Ads purchase")
		await get_tree().create_timer(0.5).timeout
		_grant()
		purchase_finished.emit(Constants.REMOVE_ADS_PRODUCT_ID, true, "simulated")
	else:
		purchase_finished.emit(Constants.REMOVE_ADS_PRODUCT_ID, false, "store unavailable")


func restore() -> void:
	if _rc:
		_rc.restore_purchases()
	else:
		restore_finished.emit(0)


func _has_entitlement() -> bool:
	return _rc != null and bool(_rc.has_entitlement(ENTITLEMENT))


## Grants Remove Ads whenever the entitlement is active (purchase, restore, Family Sharing,
## a purchase made on another device …). Returns whether it is active.
func _sync() -> bool:
	if _has_entitlement():
		_grant()
		return true
	return false


func _on_customer_info(_data: Variant) -> void:
	_sync()


func _on_purchase_result(data: Dictionary) -> void:
	if bool(data.get("success", false)):
		if not _sync():
			_grant() # entitlement not refreshed yet; the store said yes
		purchase_finished.emit(Constants.REMOVE_ADS_PRODUCT_ID, true, "")
		return
	var err := str(data.get("error", "")).to_lower()
	var reason := "error"
	if bool(data.get("cancelled", false)) or "cancel" in err:
		reason = "cancelled"
	elif "pending" in err or "deferred" in err or "ask to buy" in err:
		reason = "pending" # Ask to Buy: arrives later via customer_info_changed
	purchase_finished.emit(Constants.REMOVE_ADS_PRODUCT_ID, false, reason)


func _on_products(data: Dictionary) -> void:
	var raw: Variant = data.get("products", [])
	if not (raw is Array):
		return
	for prod in raw:
		if str(prod.get("id", "")) == Constants.REMOVE_ADS_PRODUCT_ID:
			remove_ads_price = str(prod.get("price", remove_ads_price))
			price_updated.emit(Constants.REMOVE_ADS_PRODUCT_ID, remove_ads_price)


func _on_restore_finished(data: Dictionary) -> void:
	var restored := 1 if bool(data.get("success", false)) and _sync() else 0
	restore_finished.emit(restored)


func _grant() -> void:
	if not SaveManager.ads_removed:
		SaveManager.ads_removed = true
		_log("Remove Ads granted")


func _log(msg: String) -> void:
	if OS.is_debug_build():
		print("[PurchaseManager] ", msg)
