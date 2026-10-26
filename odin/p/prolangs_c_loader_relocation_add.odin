package prolangs_c_loader_relocation_add

import "core:c"

// Copyright (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
@(export)
prolangs_c_loader_relocation_add :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 5 do return -1
	half_bytes := input[0]
	delta := input[1]
	if half_bytes < 1 || half_bytes > 6 || delta < -65535 || delta > 65535 do return -1
	width := int((half_bytes + 1) / 2)
	if int(length) != 2 + width do return -1
	field: u32 = 0
	for i in 0..<width {
		byte := input[2 + i]
		if byte < 0 || byte > 255 do return -1
		field = field * 256 + u32(byte)
	}
	adjusted := i64(field) + delta
	if adjusted < 0 do return -1
	if capacity < c.size_t(width) || output == nil do return -2
	result := u32(adjusted)
	for i := width; i > 0; i -= 1 { output[i-1] = u8(result & 255); result >>= 8 }
	return i64(width)
}
