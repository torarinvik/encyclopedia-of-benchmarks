package main

import "core:c"

// Independent bounded ROP3 profile. Full AFPL v5 terms are bundled with package.
@(export)
cbench_ghostscript_rop3 :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 5 || (length > 0 && values == nil) || length != 4 do return -1
	for i := 0; i < 3; i += 1 {
		if values[i] < 0 || values[i] > 4_294_967_295 do return -1
	}
	if values[3] < 0 || values[3] > 255 do return -1
	d, s, t, code := u64(values[0]), u64(values[1]), u64(values[2]), u64(values[3])
	result: u64 = 0
	for bit := u64(0); bit < 32; bit += 1 {
		index := ((t >> bit) & 1) << 2 | ((s >> bit) & 1) << 1 | ((d >> bit) & 1)
		if ((code >> index) & 1) != 0 do result |= u64(1) << bit
	}
	return i64(result)
}
