package wiggle_sort_strict

import "core:c"

MAX_ARRAY_LENGTH :: 4096

store_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

@(export)
wiggle_sort_strict :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > c.size_t(MAX_ARRAY_LENGTH) || (length != 0 && input == nil) do return -1
	if output_capacity < length * 4 || (length != 0 && output == nil) do return -2
	values: [MAX_ARRAY_LENGTH]i64
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
	median_count := 0
	smallest_value := values[0]
	for index := 0; index < int(length); index += 1 {
		if values[index] == median { median_count += 1 }
		if values[index] < smallest_value { smallest_value = values[index] }
	}
	maximum_medians := (int(length) + 1) / 2
	if median_count > maximum_medians || (int(length) % 2 == 1 && median_count == maximum_medians && smallest_value != median) do return -1

	i := 0
	j := 0
	k := int(length) - 1
	modulus := int(length) + 1 - (int(length) % 2)
	for j <= k {
		mapped_j := (2 * j + 1) % modulus
		if values[mapped_j] > median {
			mapped_i := (2 * i + 1) % modulus
			temporary := values[mapped_j]
			values[mapped_j] = values[mapped_i]
			values[mapped_i] = temporary
			i += 1
			j += 1
		} else if values[mapped_j] < median {
			mapped_k := (2 * k + 1) % modulus
			temporary := values[mapped_j]
			values[mapped_j] = values[mapped_k]
			values[mapped_k] = temporary
			k -= 1
		} else {
			j += 1
		}
	}
	for i := 0; i < int(length); i += 1 {
		store_i32_le(output, i * 4, values[i])
	}
	return i64(length)
}
