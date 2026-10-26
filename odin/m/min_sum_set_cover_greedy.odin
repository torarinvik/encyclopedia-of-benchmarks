package min_sum_set_cover_greedy

import "core:c"

MAX_N :: 12
MAX_M :: 16
MAX_INPUT :: 18

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
min_sum_set_cover_greedy :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n64, m64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_N || m64 < 1 || m64 > MAX_M || length != c.size_t(2+m64) do return -1
	n, m := int(n64), int(m64)
	masks: [MAX_M]u64
	for set := 0; set < m; set += 1 {
		raw := input[2+set]
		if raw <= 0 || u64(raw) >= (u64(1)<<n) do return -1
		masks[set] = u64(raw)
	}
	output_bytes := 8*(n+1)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	covered: [MAX_M]bool
	used: [MAX_N]bool
	order: [MAX_N]i64
	total_time: i64 = 0
	for slot := 1; slot <= n; slot += 1 {
		chosen, best_count := 0, -1
		for element := 0; element < n; element += 1 {
			if used[element] do continue
			count := 0
			for set := 0; set < m; set += 1 {
				if !covered[set] && (masks[set] & (u64(1)<<element)) != 0 do count += 1
			}
			if count > best_count { best_count, chosen = count, element }
		}
		used[chosen] = true
		order[slot-1] = i64(chosen)
		for set := 0; set < m; set += 1 {
			if !covered[set] && (masks[set] & (u64(1)<<chosen)) != 0 {
				covered[set] = true
				total_time += i64(slot)
			}
		}
	}
	store_i64_le(output, 0, total_time)
	for i := 0; i < n; i += 1 do store_i64_le(output, 8*(i+1), order[i])
	return i64(output_bytes)
}
