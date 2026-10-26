package beebs_bit_compress

import "core:c"

@(export)
beebs_bit_compress :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	if values[0] < 0 || values[0] > 4_294_967_295 ||
	   values[1] < 0 || values[1] > 4_294_967_295 do return -1
	data := u32(values[0])
	mask := u32(values[1])
	packed: u32 = 0
	output_bit: u32 = 1
	for mask != 0 {
		if (mask & 1) != 0 {
			if (data & 1) != 0 { packed |= output_bit }
			output_bit <<= 1
		}
		data >>= 1
		mask >>= 1
	}
	return i64(packed)
}
