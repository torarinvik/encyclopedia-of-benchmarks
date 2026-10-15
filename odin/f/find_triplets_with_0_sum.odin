package find_triplets_with_0_sum

import "core:c"

MAX_ITEMS :: 64
BYTES_PER_TRIPLET :: 12

write_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 { output[offset + byte] = u8((bits >> u32(byte * 8)) & 255) }
}

enumerate :: proc "contextless" (values: [^]i64, length: int, output: [^]u8, write_output: bool) -> int {
	count := 0
	has_last := false
	last_a, last_b, last_c: i64 = 0, 0, 0
	for i := 0; i + 2 < length; i += 1 {
		for j := i + 1; j + 1 < length; j += 1 {
			for k := j + 1; k < length; k += 1 {
				if values[i] + values[j] + values[k] != 0 do continue
				if has_last && values[i] == last_a && values[j] == last_b && values[k] == last_c do continue
				if write_output {
					offset := count * BYTES_PER_TRIPLET
					write_i32_le(output, offset, values[i])
					write_i32_le(output, offset + 4, values[j])
					write_i32_le(output, offset + 8, values[k])
				}
				last_a, last_b, last_c = values[i], values[j], values[k]
				has_last = true
				count += 1
			}
		}
	}
	return count
}

@(export)
find_triplets_with_0_sum :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_ITEMS || (length > 0 && input == nil) do return -1
	values: [MAX_ITEMS]i64
	for i := c.size_t(0); i < length; i += 1 {
		if input[i] < -100000 || input[i] > 100000 do return -1
		values[i] = input[i]
	}
	for i := 1; i < int(length); i += 1 {
		key := values[i]
		j := i
		for j > 0 && values[j - 1] > key { values[j] = values[j - 1]; j -= 1 }
		values[j] = key
	}
	count := enumerate(&values[0], int(length), nil, false)
	if count == 0 do return 0
	needed := c.size_t(count * BYTES_PER_TRIPLET)
	if output == nil || output_capacity < needed do return -2
	return i64(enumerate(&values[0], int(length), output, true))
}
