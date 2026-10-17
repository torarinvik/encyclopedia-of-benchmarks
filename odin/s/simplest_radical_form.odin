package simplest_radical_form

import "core:c"

put_i64 :: proc(output: [^]u8, offset: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> (byte * 8))
	}
}

@(export)
simplest_radical_form :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length != 1 do return -1
	original := values[0]
	if original < 0 || original > 100000000 do return -1
	if output == nil || capacity < 16 do return -2

	coefficient, root_term := i64(1), i64(1)
	if original == 0 {
		root_term = 0
	} else {
		remainder := original
		factor := i64(2)
		for factor * factor <= original {
			count := i64(0)
			for remainder % factor == 0 {
				remainder /= factor
				count += 1
			}
			for power := i64(0); power < count / 2; power += 1 { coefficient *= factor }
			if count % 2 != 0 do root_term *= factor
			factor += 1
		}
		root_term *= remainder
	}
	put_i64(output, 0, coefficient)
	put_i64(output, 8, root_term)
	return 16
}
