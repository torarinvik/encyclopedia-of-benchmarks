package comb_list_update

import "core:c"

MAX_N :: 8
MAX_REQUESTS :: 32
MAX_INPUT :: 82
MAX_OUTPUT_BYTES :: 392

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
comb_list_update :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n_raw, requests_raw := input[0], input[1]
	if n_raw < 1 || n_raw > MAX_N || requests_raw < 0 || requests_raw > MAX_REQUESTS do return -1
	n, requests := int(n_raw), int(requests_raw)
	if length != c.size_t(2+2*n+2*requests) do return -1
	order: [MAX_N]int = {}; seen: [MAX_N]bool = {}
	for i := 0; i < n; i += 1 { page := input[2+i]; if page < 0 || page >= n_raw || seen[int(page)] do return -1; order[i] = int(page); seen[int(page)] = true }
	request_ids: [MAX_REQUESTS]int = {}
	for i := 0; i < requests; i += 1 { page := input[2+n+i]; if page < 0 || page >= n_raw do return -1; request_ids[i] = int(page) }
	bits: [MAX_N]i64 = {}
	for i := 0; i < n; i += 1 { bit := input[2+n+requests+i]; if bit != 0 && bit != 1 do return -1; bits[i] = bit }
	modes: [MAX_REQUESTS]int = {}
	for i := 0; i < requests; i += 1 { mode := input[2+2*n+requests+i]; if mode < 0 || mode > 4 do return -1; modes[i] = int(mode) }
	last_request: [MAX_N]int = {}; for i := 0; i < n; i += 1 { last_request[i] = -1 }
	positions: [MAX_REQUESTS]i64 = {}; total_cost: i64 = 0
	for time := 0; time < requests; time += 1 {
		page := request_ids[time]; position := 0
		for position < n && order[position] != page { position += 1 }
		if position == n do return -1
		positions[time] = i64(position+1); total_cost += i64(position+1)
		if modes[time] < 4 {
			bits[page] ^= 1
			if bits[page] == 1 && position > 0 { for shift := position; shift > 0; shift -= 1 { order[shift] = order[shift-1] }; order[0] = page }
		} else if last_request[page] >= 0 {
			for target := 0; target < position; target += 1 {
				candidate := order[target]; occurrences := 0
				for t := last_request[page]+1; t < time; t += 1 { if request_ids[t] == candidate { occurrences += 1 } }
				if occurrences <= 1 { for shift := position; shift > target; shift -= 1 { order[shift] = order[shift-1] }; order[target] = page; break }
			}
		}
		last_request[page] = time
	}
	words: [1+2*MAX_N+MAX_REQUESTS]i64 = {}; words[0] = total_cost
	for i := 0; i < n; i += 1 { words[1+i] = i64(order[i]) }
	for i := 0; i < requests; i += 1 { words[1+n+i] = positions[i] }
	for i := 0; i < n; i += 1 { words[1+n+requests+i] = bits[i] }
	output_bytes := 8*(1+2*n+requests)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	for word := 0; word < 1+2*n+requests; word += 1 { store_i64_le(&staged[0], 8*word, words[word]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
