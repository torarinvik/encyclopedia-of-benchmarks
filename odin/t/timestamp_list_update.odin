package timestamp_list_update

import "core:c"

MAX_N :: 8
MAX_REQUESTS :: 32
MAX_INPUT :: 42
MAX_OUTPUT_BYTES :: 328

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
timestamp_list_update :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n_raw, requests_raw := input[0], input[1]
	if n_raw < 1 || n_raw > MAX_N || requests_raw < 0 || requests_raw > MAX_REQUESTS do return -1
	n, requests := int(n_raw), int(requests_raw)
	if length != c.size_t(2+n+requests) do return -1
	order: [MAX_N]int = {}
	seen: [MAX_N]bool = {}
	for i := 0; i < n; i += 1 {
		item := input[2+i]
		if item < 0 || item >= n_raw || seen[int(item)] do return -1
		order[i] = int(item); seen[int(item)] = true
	}
	request_ids: [MAX_REQUESTS]int = {}
	for i := 0; i < requests; i += 1 {
		item := input[2+n+i]
		if item < 0 || item >= n_raw do return -1
		request_ids[i] = int(item)
	}
	last_request: [MAX_N]int = {}
	for i := 0; i < n; i += 1 { last_request[i] = -1 }
	positions: [MAX_REQUESTS]i64 = {}
	total_cost: i64 = 0
	for time := 0; time < requests; time += 1 {
		item := request_ids[time]
		position := 0
		for position < n && order[position] != item { position += 1 }
		if position == n do return -1
		positions[time] = i64(position+1); total_cost += i64(position+1)
		if last_request[item] >= 0 {
			for target := 0; target < position; target += 1 {
				candidate := order[target]
				occurrences := 0
				for t := last_request[item]+1; t < time; t += 1 { if request_ids[t] == candidate { occurrences += 1 } }
				if occurrences <= 1 {
					for shift := position; shift > target; shift -= 1 { order[shift] = order[shift-1] }
					order[target] = item; break
				}
			}
		}
		last_request[item] = time
	}
	words: [1+MAX_N+MAX_REQUESTS]i64 = {}
	words[0] = total_cost
	for i := 0; i < n; i += 1 { words[1+i] = i64(order[i]) }
	for i := 0; i < requests; i += 1 { words[1+n+i] = positions[i] }
	output_bytes := 8*(1+n+requests)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	for word := 0; word < 1+n+requests; word += 1 { store_i64_le(&staged[0], 8*word, words[word]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
