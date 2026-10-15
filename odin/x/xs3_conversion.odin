package xs3_conversion

import "core:c"

@(export)
xs3_conversion :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if length != 2 do return -1
	direction := packed[0]
	value := packed[1]
	if direction == 0 {
		if value < 0 || value > 2147483647 do return -1
		decoded: i64 = 0
		multiplier: i64 = 1
		for value > 0 {
			nibble := value & 15
			if nibble < 3 || nibble > 12 do return -1
			decoded += (nibble - 3) * multiplier
			multiplier *= 10
			value >>= 4
		}
		return decoded
	}
	if direction == 1 {
		if value < 0 || value > 9999999 do return -1
		encoded: i64 = 0
		shift: u32 = 0
		for value > 0 {
			digit := value % 10 + 3
			encoded |= digit << (shift * 4)
			value /= 10
			shift += 1
		}
		return encoded
	}
	return -1
}
