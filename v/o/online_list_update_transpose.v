module online_list_update_transpose

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

@[export: 'online_list_update_transpose']
pub fn online_list_update_transpose(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_raw := input[0]
		requests_raw := input[1]
		if n_raw < 1 || n_raw > max_n || requests_raw < 0 || requests_raw > max_requests { return -1 }
		n := int(n_raw)
		request_count := int(requests_raw)
		if length != 2 + n + request_count { return -1 }
		mut order := [max_n]int{}
		mut seen := [max_n]bool{}
		for i in 0 .. n {
			item := input[2 + i]
			if item < 0 || item >= n_raw || seen[int(item)] { return -1 }
			order[i] = int(item)
			seen[int(item)] = true
		}
		mut positions := [max_requests]i64{}
		mut total_cost := i64(0)
		for request in 0 .. request_count {
			item_raw := input[2 + n + request]
			if item_raw < 0 || item_raw >= n_raw { return -1 }
			mut position := 0
			for position < n && order[position] != int(item_raw) { position++ }
			if position == n { return -1 }
			positions[request] = i64(position + 1)
			total_cost += i64(position + 1)
			if position > 0 {
				previous := order[position - 1]
				order[position - 1] = order[position]
				order[position] = previous
				total_cost++
			}
		}
		mut words := [1 + max_n + max_requests]i64{}
		words[0] = total_cost
		for i in 0 .. n { words[1 + i] = i64(order[i]) }
		for i in 0 .. request_count { words[1 + n + i] = positions[i] }
		output_bytes := 8 * (1 + n + request_count)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		for word in 0 .. 1 + n + request_count { put_i64_le(mut staged[0], 8 * word, words[word]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
