package decimal_to_hex

import "core:c"

@(export)
decimal_to_hex :: proc "c" (value_input: i64, output: [^]u8, capacity: c.size_t) -> i64 {
	if value_input < 0 || value_input > 9_007_199_254_740_991 do return -1
	value := value_input
	width: usize = 1
	for n := value; n >= 16; n /= 16 { width += 1 }
	if output == nil || capacity < width do return -2
	position := width
	for {
		if position == 0 do break
		position -= 1
		digit := value % 16
		if digit < 10 do output[position] = u8('0' + digit)
		else do output[position] = u8('A' + digit - 10)
		value /= 16
	}
	return i64(width)
}
