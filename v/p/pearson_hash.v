module pearson_hash

const table_size = 256
const max_text = 64
const max_words = 1 + table_size + max_text

@[export: 'pearson_hash']
pub fn pearson_hash(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 + table_size || length > max_words + 1 { return -1 }
	declared := unsafe { input[0] }
	if declared < 0 || declared > max_text || length != usize(1 + table_size) + usize(declared) { return -1 }
	mut table := [table_size]u8{}
	mut used := [table_size]bool{}
	for slot in 0 .. table_size {
		value := unsafe { input[1 + slot] }
		if value < 0 || value > 255 { return -1 }
		byte := int(value)
		if used[byte] { return -1 }
		used[byte] = true
		table[slot] = u8(byte)
	}
	text_start := 1 + table_size
	for offset in 0 .. int(declared) {
		value := unsafe { input[text_start + offset] }
		if value < 0 || value > 255 { return -1 }
	}
	mut state := u8(0)
	for offset in 0 .. int(declared) {
		byte := u8(unsafe { input[text_start + offset] })
		state = table[int(state ^ byte)]
	}
	return i64(state)
}
