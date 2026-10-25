package main

import "core:c"

// Independent ROP3 truth-table transforms; complete AFPL v5 is bundled.
@(export)
cbench_ghostscript_rop3_transform :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 3 || (length > 0 && values == nil) || length != 2 do return -1
	if values[0] < 0 || values[0] > 14 || values[1] < 0 || values[1] > 255 do return -1
	mode := int(values[0]); code := u64(values[1])
	result: u64 = 0
	for index := 0; index < 8; index += 1 {
		d := index & 1; s := (index >> 1) & 1; t := (index >> 2) & 1
		source_index := index
		forced := -1
		if mode <= 2 { source_index ^= 1 << mode }
		else if mode <= 8 { dimension := (mode-3)/2; pinned := (mode-3)&1; source_index = (index & ~(1 << dimension)) | (pinned << dimension) }
		else if mode == 9 { source_index = (index & ~6) | (s << 2) | (t << 1) }
		else if mode <= 13 { operand := s; if mode >= 12 do operand = t; if operand == ((mode-10)&1) do forced = d }
		else { forced = 1 - int((code >> u64(index)) & 1) }
		bit := forced
		if forced < 0 do bit = int((code >> u64(source_index)) & 1)
		result |= u64(bit) << u64(index)
	}
	return i64(result)
}
