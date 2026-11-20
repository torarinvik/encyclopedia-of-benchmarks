package k_subset_colex_rank_unrank

import "core:c"

MAX_N :: 16
MAX_K :: 16
MAX_INPUT :: 20

choose_small :: proc(n, k_value: int) -> i64 {
	if n < 0 || k_value < 0 || k_value > n { return 0 }
	k := k_value
	if k > n-k { k = n-k }
	value := i64(1)
	for i := 1; i <= k; i += 1 { value = value*i64(n-k+i)/i64(i) }
	return value
}

store_i64_le :: proc(output: [^]u8, index: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[index*8+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
k_subset_colex_rank_unrank :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT do return -1
	if length < 3 do return -1
	mode := input[0]
	if mode != 0 && mode != 1 do return -1
	raw_n, raw_k := input[1], input[2]
	if raw_n < 0 || raw_n > MAX_N || raw_k < 0 || raw_k > raw_n do return -1
	n, k := int(raw_n), int(raw_k)
	indices: [MAX_K]i64 = {}
	rank := i64(0)

	if mode == 0 {
		if int(length) != 3+k do return -1
		for i := 0; i < k; i += 1 {
			index := input[3+i]
			if index < 0 || index >= raw_n || (i > 0 && indices[i-1] >= index) do return -1
			indices[i] = index
			rank += choose_small(int(index), i+1)
		}
	} else {
		if length != 4 do return -1
		rank = input[3]
		if rank < 0 || rank >= choose_small(n, k) do return -1
		upper, remainder := n-1, rank
		for order := k; order >= 1; order -= 1 {
			candidate := upper
			for candidate >= 0 && choose_small(candidate, order) > remainder { candidate -= 1 }
			if candidate < 0 do return -1
			indices[order-1] = i64(candidate)
			remainder -= choose_small(candidate, order)
			upper = candidate-1
		}
	}

	words := k+1
	needed := c.size_t(words*8)
	if output == nil || capacity < needed do return -2
	store_i64_le(output, 0, rank)
	for i := 0; i < k; i += 1 { store_i64_le(output, i+1, indices[i]) }
	return i64(needed)
}
