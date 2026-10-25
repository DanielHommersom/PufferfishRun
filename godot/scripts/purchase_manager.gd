extends Node
## In-app purchases via Godot's official iOS "InAppStore" plugin (godot-ios-plugins).
## Only product: the non-consumable "Remove Ads", which turns off interstitials for good.
## Without the plugin: debug builds simulate the purchase so it can be tested on a Mac;
## release builds report the store as unavailable.

signal purchase_finished(product_id: String, success: bool, message: String)
signal restore_finished(restored: int)
signal price_updated(product_id: String, price: String)

const SINGLETON := "InAppStore"

var remove_ads_price := Constants.REMOVE_ADS_FALLBACK_PRICE
var _store: Object
var _restored := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton(SINGLETON):
		_store = Engine.get_singleton(SINGLETON)
		_store.set_auto_finish_transaction(true)
		_store.request_product_info({"product_ids": PackedStringArray([Constants.REMOVE_ADS_PRODUCT_ID])})
	else:
		_log("no InAppStore plugin — purchases %s" % ("simulated" if OS.is_debug_build() else "unavailable"))


func is_available() -> bool:
	return _store != null or OS.is_debug_build()


func buy_remove_ads() -> void:
	if SaveManager.ads_removed:
		purchase_finished.emit(Constants.REMOVE_ADS_PRODUCT_ID, true, "already owned")
		return
	if _store:
		var err = _store.purchase({"product_id": Constants.REMOVE_ADS_PRODUCT_ID})
		if err != OK:
			purchase_finished.emit(Constants.REMOVE_ADS_PRODUCT_ID, false, "could not start purchase")
	elif OS.is_debug_build():
		_log("simulating Remove Ads purchase")
		await get_tree().create_timer(0.5).timeout
		_grant(Constants.REMOVE_ADS_PRODUCT_ID)
		purchase_finished.emit(Constants.REMOVE_ADS_PRODUCT_ID, true, "simulated")
	else:
		purchase_finished.emit(Constants.REMOVE_ADS_PRODUCT_ID, false, "store unavailable")


func restore() -> void:
	_restored = 0
	if _store:
		_store.restore_purchases()
	else:
		restore_finished.emit(0)


func _process(_delta: float) -> void:
	if _store == null:
		return
	while _store.get_pending_event_count() > 0:
		_handle(_store.pop_pending_event())


func _handle(event: Dictionary) -> void:
	var type: String = event.get("type", "")
	var result: String = event.get("result", "")
	var product: String = event.get("product_id", "")
	match type:
		"product_info":
			var ids: Array = event.get("ids", [])
			var prices: Array = event.get("localized_prices", [])
			for i in ids.size():
				if ids[i] == Constants.REMOVE_ADS_PRODUCT_ID and i < prices.size():
					remove_ads_price = str(prices[i])
					price_updated.emit(ids[i], remove_ads_price)
		"purchase":
			if result == "ok":
				_grant(product)
				purchase_finished.emit(product, true, "")
			elif result != "progress":
				purchase_finished.emit(product, false, str(event.get("error", "cancelled")))
		"restore":
			if result == "ok":
				_grant(product)
				_restored += 1
			elif result == "completed" or result == "error":
				restore_finished.emit(_restored)


func _grant(product_id: String) -> void:
	if product_id == Constants.REMOVE_ADS_PRODUCT_ID:
		SaveManager.ads_removed = true
		_log("Remove Ads granted")


func _log(msg: String) -> void:
	if OS.is_debug_build():
		print("[PurchaseManager] ", msg)
