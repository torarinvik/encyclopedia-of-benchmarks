package weighted_greedy_set_cover

import "core:c"

MAX_N :: 16
MAX_M :: 16
MAX_INPUT :: 34
MAX_OUTPUT :: 136

put64 :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[position + byte] = u8(bits & 255); bits >>= 8 }
}

bit_count :: proc(value: u64) -> int {
	bits := value
	count := 0
	for bits != 0 { bits &= bits-1; count += 1 }
	return count
}

@(export)
weighted_greedy_set_cover :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n64, m64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_N || m64 < 1 || m64 > MAX_M || length != c.size_t(2+2*m64) do return -1
	n, m := int(n64), int(m64)
	full := (u64(1) << n) - 1
	weight: [MAX_M]i64
	mask: [MAX_M]u64
	union_mask := u64(0)
	for set := 0; set < m; set += 1 {
		weight[set] = input[2+set]
		mask_value := input[2+m+set]
		if weight[set] < 0 || weight[set] > 10000 || mask_value < 0 || (u64(mask_value)&~full) != 0 do return -1
		mask[set] = u64(mask_value)
		union_mask |= mask[set]
	}
	if union_mask != full do return -1

	covered := u64(0)
	selected: [MAX_M]int
	selected_count := 0
	for covered != full {
		best, best_gain := -1, 0
		for set := 0; set < m; set += 1 {
			gain := bit_count(mask[set] & ~covered)
			if gain == 0 do continue
			if best < 0 || weight[set]*i64(best_gain) < weight[best]*i64(gain) {
				best, best_gain = set, gain
			}
		}
		if best < 0 do return -1
		selected[selected_count] = best
		selected_count += 1
		covered |= mask[best]
	}
	output_bytes := 8*(selected_count+1)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT]u8
	put64(&staged[0], 0, i64(selected_count))
	for index := 0; index < selected_count; index += 1 { put64(&staged[0], 8*(index+1), i64(selected[index])) }
	for index := 0; index < output_bytes; index += 1 { output[index] = staged[index] }
	return i64(output_bytes)
}
