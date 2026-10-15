package weighted_interval_scheduling

import "core:c"

MAX_INTERVALS :: 64
MAX_INPUT_LENGTH :: 193

start_at :: proc "contextless" (input: [^]i64, index: int) -> i64 { return input[1 + index * 3] }
end_at :: proc "contextless" (input: [^]i64, index: int) -> i64 { return input[2 + index * 3] }
weight_at :: proc "contextless" (input: [^]i64, index: int) -> i64 { return input[3 + index * 3] }

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte: int = 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}
put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := transmute(u32)value
	for byte: int = 0; byte < 4; byte += 1 { output[offset + byte] = u8(bits >> u32(8 * byte)) }
}

@(export)
weighted_interval_scheduling :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH || input[0] < 0 || input[0] > MAX_INTERVALS do return -1
	n := int(input[0])
	if int(length) != 1 + 3 * n do return -1
	for i := 0; i < n; i += 1 {
		start := start_at(input, i); finish := end_at(input, i); weight := weight_at(input, i)
		if start < -100000 || start > 100000 || finish < -100000 || finish > 100000 || start >= finish || weight < 0 || weight > 1000000 do return -1
	}
	order: [MAX_INTERVALS]int
	predecessors: [MAX_INTERVALS]int
	selected: [MAX_INTERVALS]int
	dp: [MAX_INTERVALS + 1]i64 = {}
	for i := 0; i < n; i += 1 { order[i] = i }
	for i := 1; i < n; i += 1 {
		key := order[i]; j := i
		for j > 0 && end_at(input, order[j - 1]) > end_at(input, key) { order[j] = order[j - 1]; j -= 1 }
		order[j] = key
	}
	for j := 0; j < n; j += 1 {
		low, high := 0, n
		for low < high {
			mid := low + (high - low) / 2
			if end_at(input, order[mid]) <= start_at(input, order[j]) { low = mid + 1 }
			else { high = mid }
		}
		predecessors[j] = low
		include := weight_at(input, order[j]) + dp[low]
		if include > dp[j] { dp[j + 1] = include } else { dp[j + 1] = dp[j] }
	}
	selected_count, current := 0, n
	for current > 0 {
		j := current - 1
		include := weight_at(input, order[j]) + dp[predecessors[j]]
		if include > dp[current - 1] { selected[selected_count] = order[j]; selected_count += 1; current = predecessors[j] }
		else { current -= 1 }
	}
	for i := 0; i < selected_count / 2; i += 1 {
		temp := selected[i]; selected[i] = selected[selected_count - 1 - i]; selected[selected_count - 1 - i] = temp
	}
	needed := 16 + 4 * selected_count
	if output == nil || int(capacity) < needed do return -2
	put_i64_le(output, 0, dp[n]); put_i64_le(output, 8, i64(selected_count))
	for i := 0; i < selected_count; i += 1 { put_i32_le(output, 16 + 4 * i, i32(selected[i])) }
	return i64(needed)
}
