package pearson_hash

import "core:c"

TABLE_SIZE :: 256
MAX_TEXT :: 64
MAX_WORDS :: 1 + TABLE_SIZE + MAX_TEXT

@(export)
pearson_hash :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 + TABLE_SIZE || length > MAX_WORDS + 1 do return -1
	declared := input[0]
	if declared < 0 || declared > MAX_TEXT || length != c.size_t(1 + TABLE_SIZE) + c.size_t(declared) do return -1

	table: [TABLE_SIZE]u8
	used: [TABLE_SIZE]bool
	for slot := 0; slot < TABLE_SIZE; slot += 1 {
		value := input[1 + slot]
		if value < 0 || value > 255 do return -1
		byte := int(value)
		if used[byte] do return -1
		used[byte] = true
		table[slot] = u8(byte)
	}

	text_start := 1 + TABLE_SIZE
	for offset := 0; offset < int(declared); offset += 1 {
		value := input[text_start + offset]
		if value < 0 || value > 255 do return -1
	}
	state: u8 = 0
	for offset := 0; offset < int(declared); offset += 1 {
		byte := u8(input[text_start + offset])
		state = table[int(state ^ byte)]
	}
	return i64(state)
}
