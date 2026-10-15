package simplified_wiggle_sort

import "core:c"

MAX_ARRAY_LENGTH :: 4096

store_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

@(export)
simplified_wiggle_sort :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > c.size_t(MAX_ARRAY_LENGTH) || (length != 0 && input == nil) do return -1
	if output_capacity < length * 4 || (length != 0 && output == nil) do return -2
	values: [MAX_ARRAY_LENGTH]i64
	ordered: [MAX_ARRAY_LENGTH]i64
	for i := 0; i < int(length); i += 1 {
		value := input[i]
		if value < -2_147_483_648 || value > 2_147_483_647 do return -1
		values[i] = value
	}
	if length == 0 do return 0

	low := 0
	high := int(length) - 1
	target := int(length) / 2
	for low < high {
		left := low
		right := high
		pivot := values[(left + right + 1) / 2]
		for left <= right {
			for left <= right && values[left] < pivot { left += 1 }
			for left <= right && values[right] > pivot { right -= 1 }
			if left <= right {
				temporary := values[left]
				values[left] = values[right]
				values[right] = temporary
				left += 1
				right -= 1
			}
		}
		if target <= right { high = right }
		else if target >= left { low = left }
		else { break }
	}
	median := values[target]
	smaller := 0
	greater := int(length) - 1 - (int(length) % 2)
	for i := 0; i < int(length); i += 1 {
		if values[i] > median {
			ordered[greater] = values[i]
			greater -= 2
		} else if smaller < int(length) {
			ordered[smaller] = values[i]
			smaller += 2
		} else {
			ordered[greater] = values[i]
			greater -= 2
		}
	}
	for i := 0; i < int(length); i += 1 {
		store_i32_le(output, i * 4, ordered[i])
	}
	return i64(length)
}
