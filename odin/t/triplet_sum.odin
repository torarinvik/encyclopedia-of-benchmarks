package triplet_sum

import "core:c"

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

sort_three :: proc "contextless" (first, second, third: ^i64) {
	if first^ > second^ { first^, second^ = second^, first^ }
	if second^ > third^ { second^, third^ = third^, second^ }
	if first^ > second^ { first^, second^ = second^, first^ }
}

@(export)
triplet_sum :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	max_items :: 10
	if input == nil || length < 1 || length > max_items + 1 { return -1 }
	target := input[0]
	if target < -3_000_000 || target > 3_000_000 { return -1 }
	item_count := int(length - 1)
	for index := 0; index < item_count; index += 1 {
		if input[index + 1] < -1_000_000 || input[index + 1] > 1_000_000 { return -1 }
	}
	if output_capacity < 24 || output == nil { return -2 }

	result: [3]i64
	found := false
	for first := 0; first < item_count && !found; first += 1 {
		for second := 0; second < item_count && !found; second += 1 {
			if second == first { continue }
			for third := 0; third < item_count; third += 1 {
				if third == first || third == second { continue }
				a, b, d := input[first + 1], input[second + 1], input[third + 1]
				if a + b + d == target {
					result = [3]i64{a, b, d}
					sort_three(&result[0], &result[1], &result[2])
					found = true
					break
				}
			}
		}
	}
	for index := 0; index < 3; index += 1 { put_i64_le(output, index * 8, result[index]) }
	return 3
}
