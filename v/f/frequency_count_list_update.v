module frequency_count_list_update

import core.c

const (
	max_n = 8
	max_requests = 32
	max_input = 42
	max_output_bytes = 328
)

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'frequency_count_list_update']
pub fn frequency_count_list_update(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_raw := input[0]
		requests_raw := input[1]
		if n_raw < 1 || n_raw > max_n || requests_raw < 0 || requests_raw > max_requests { return -1 }
		n, requests := int(n_raw), int(requests_raw)
		if length != usize(2+n+requests) { return -1 }
		mut order := [max_n]int{}
		mut seen := [max_n]bool{}
		for i in 0 .. n {
			item := input[2+i]
			if item < 0 || item >= n_raw || seen[int(item)] { return -1 }
			order[i] = int(item); seen[int(item)] = true
		}
		mut request_ids := [max_requests]int{}
		for i in 0 .. requests {
			item := input[2+n+i]
			if item < 0 || item >= n_raw { return -1 }
			request_ids[i] = int(item)
		}
		mut counts := [max_n]i64{}
		mut positions := [max_requests]i64{}
		mut total_cost := i64(0)
		for request in 0 .. requests {
			item := request_ids[request]
			mut position := 0
			for position < n && order[position] != item { position++ }
			if position == n { return -1 }
			positions[request] = i64(position+1); total_cost += i64(position+1); counts[item]++
			for position > 0 && counts[item] > counts[order[position-1]] {
				previous := order[position-1]; order[position-1] = item; order[position] = previous; position--
			}
		}
		mut words := [1+max_n+max_requests]i64{}
		words[0] = total_cost
		for i in 0 .. n { words[1+i] = i64(order[i]) }
		for i in 0 .. requests { words[1+n+i] = positions[i] }
		output_bytes := 8*(1+n+requests)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		for word in 0 .. 1+n+requests { put_i64_le(mut staged[0], 8*word, words[word]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
