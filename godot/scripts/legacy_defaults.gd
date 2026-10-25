class_name LegacyDefaults
## Reads the Swift build's NSUserDefaults (US-25) straight from its preferences file — no native
## plugin needed. iOS keeps it in the app container at
## Library/Preferences/<bundle id>.plist (binary plist), next to Godot's Documents (user://).
## Only the types the Swift build stored are supported: dict, string, int, bool.

const BUNDLE_ID := "digitaldiamonds.pufferfishrun"


static func plist_path() -> String:
	return OS.get_user_data_dir().get_base_dir().path_join("Library/Preferences/%s.plist" % BUNDLE_ID)


## Returns {highScore, selectedSkin, isMuted} (only the keys that exist), or {} if there is
## no legacy file or it can't be parsed.
static func read(path := "") -> Dictionary:
	if path == "":
		path = plist_path()
	if not FileAccess.file_exists(path):
		return {}
	var data := FileAccess.get_file_as_bytes(path)
	var parsed = parse_binary_plist(data)
	if not (parsed is Dictionary):
		return {}
	var out := {}
	for key in ["highScore", "selectedSkin", "isMuted"]:
		if parsed.has(key):
			out[key] = parsed[key]
	return out


## Minimal binary plist ("bplist00") reader.
static func parse_binary_plist(d: PackedByteArray) -> Variant:
	if d.size() < 40 or d.slice(0, 8).get_string_from_ascii() != "bplist00":
		return null
	var t := d.size() - 32
	var offset_size := d[t + 6]
	var ref_size := d[t + 7]
	var num_objects := _uint(d, t + 8, 8)
	var top := _uint(d, t + 16, 8)
	var table := _uint(d, t + 24, 8)
	var offsets := []
	for i in num_objects:
		offsets.append(_uint(d, table + i * offset_size, offset_size))
	return _object(d, offsets, ref_size, top, 0)


static func _uint(d: PackedByteArray, at: int, size: int) -> int:
	var v := 0
	for i in size:
		v = (v << 8) | d[at + i]
	return v


## Returns [length, start] for an object whose length lives in the low nibble or a following int.
static func _len(d: PackedByteArray, at: int) -> Array:
	var n := d[at] & 0x0F
	if n != 0x0F:
		return [n, at + 1]
	var int_marker := d[at + 1]
	var size := 1 << (int_marker & 0x0F)
	return [_uint(d, at + 2, size), at + 2 + size]


static func _object(d: PackedByteArray, offsets: Array, ref_size: int, index: int, depth: int) -> Variant:
	if depth > 8 or index >= offsets.size():
		return null
	var at: int = offsets[index]
	var marker := d[at]
	match marker >> 4:
		0x0:
			if marker == 0x08:
				return false
			if marker == 0x09:
				return true
			return null
		0x1:
			var size := 1 << (marker & 0x0F)
			var v := _uint(d, at + 1, size)
			if size == 8 and v >= (1 << 63): # signed 64-bit
				v -= 1 << 64
			return v
		0x5:
			var l := _len(d, at)
			return d.slice(l[1], l[1] + l[0]).get_string_from_ascii()
		0x6:
			var l := _len(d, at)
			var s := ""
			for i in l[0]:
				s += char(_uint(d, l[1] + i * 2, 2))
			return s
		0xD:
			var l := _len(d, at)
			var dict := {}
			var count: int = l[0]
			var start: int = l[1]
			for i in count:
				var k = _object(d, offsets, ref_size, _uint(d, start + i * ref_size, ref_size), depth + 1)
				var v = _object(d, offsets, ref_size, _uint(d, start + (count + i) * ref_size, ref_size), depth + 1)
				dict[str(k)] = v
			return dict
	return null
