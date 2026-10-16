package sumset

import "core:c"

MIN_SUM :: -2000
SUM_COUNT :: 4001
MAX_SET_SIZE :: 64

decimal_width :: proc(value_input: i64) -> int {
	value := value_input
	width := 1
	if value < 0 { value = -value; width += 1 }
	for value >= 10 { value /= 10; width += 1 }
	return width
}

append_signed_decimal :: proc(output: [^]u8, position_input: int, value_input: i64) -> int {
	value := value_input
	position := position_input
	if value < 0 { output[position] = u8('-'); position += 1; value = -value }
	digits: [20]u8
	count := 0
	for {
		digits[count] = u8(value % 10)
		count += 1
		value /= 10
		if value == 0 do break
	}
	for count > 0 {
		count -= 1
		output[position] = u8('0') + digits[count]
		position += 1
	}
	return position
}

@(export)
sumset :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 do return -1
	count_a, count_b := values[0], values[1]
	if count_a < 0 || count_a > MAX_SET_SIZE || count_b < 0 || count_b > MAX_SET_SIZE ||
		length != c.size_t(2 + count_a + count_b) do return -1
	present: [SUM_COUNT]bool = {}
	for index_a := 0; index_a < int(count_a); index_a += 1 {
		if values[index_a + 2] < -1000 || values[index_a + 2] > 1000 do return -1
	}
	for index_b := 0; index_b < int(count_b); index_b += 1 {
		right := values[int(count_a) + index_b + 2]
		if right < -1000 || right > 1000 do return -1
	}
	for index_a := 0; index_a < int(count_a); index_a += 1 {
		left := values[index_a + 2]
		for index_b := 0; index_b < int(count_b); index_b += 1 {
			right := values[int(count_a) + index_b + 2]
			present[int(left + right - MIN_SUM)] = true
		}
	}
	needed := 0
	for index := 0; index < SUM_COUNT; index += 1 {
		if present[index] do needed += decimal_width(i64(index + MIN_SUM)) + 1
	}
	if needed == 0 do return 0
	if output == nil || output_capacity < c.size_t(needed) do return -2
	position := 0
	for index := 0; index < SUM_COUNT; index += 1 {
		if !present[index] do continue
		position = append_signed_decimal(output, position, i64(index + MIN_SUM))
		output[position] = u8('\n'); position += 1
	}
	return i64(position)
}
