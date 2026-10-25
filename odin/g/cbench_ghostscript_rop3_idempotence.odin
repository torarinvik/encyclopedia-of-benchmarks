package main

import "core:c"

// Independent bounded profile; complete Aladdin Free Public License v5 is bundled.
@(export)
cbench_ghostscript_rop3_idempotence :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 2 || (length > 0 && values == nil) || length != 1 do return -1
	if values[0] < 0 || values[0] > 255 do return -1
	code := u64(values[0])
	for bit := u64(1); bit < 8; bit += 2 {
		if ((code >> bit) & 1) != 0 && ((code >> (bit-1)) & 1) == 0 do return 0
	}
	return 1
}
