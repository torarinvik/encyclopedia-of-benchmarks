module comb_list_update

import core.c

const (
	max_n = 8
	max_requests = 32
	max_input = 82
	max_output_bytes = 392
)

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'comb_list_update']
pub fn comb_list_update(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		n_raw := input[0]; requests_raw := input[1]
		if n_raw < 1 || n_raw > max_n || requests_raw < 0 || requests_raw > max_requests { return -1 }
		n, requests := int(n_raw), int(requests_raw)
		if length != usize(2+2*n+2*requests) { return -1 }
		mut order := [max_n]int{}; mut seen := [max_n]bool{}
		for i in 0 .. n { page := input[2+i]; if page < 0 || page >= n_raw || seen[int(page)] { return -1 }; order[i] = int(page); seen[int(page)] = true }
		mut request_ids := [max_requests]int{}
		for i in 0 .. requests { page := input[2+n+i]; if page < 0 || page >= n_raw { return -1 }; request_ids[i] = int(page) }
		mut bits := [max_n]i64{}
		for i in 0 .. n { bit := input[2+n+requests+i]; if bit != 0 && bit != 1 { return -1 }; bits[i] = bit }
		mut modes := [max_requests]int{}
		for i in 0 .. requests { mode := input[2+2*n+requests+i]; if mode < 0 || mode > 4 { return -1 }; modes[i] = int(mode) }
		mut last_request := [max_n]int{}
		for i in 0 .. n { last_request[i] = -1 }
		mut positions := [max_requests]i64{}; mut total_cost := i64(0)
		for time in 0 .. requests {
			page := request_ids[time]; mut position := 0
			for position < n && order[position] != page { position++ }
			if position == n { return -1 }
			positions[time] = i64(position+1); total_cost += i64(position+1)
			if modes[time] < 4 {
				bits[page] ^= 1
				if bits[page] == 1 && position > 0 { for shift := position; shift > 0; shift-- { order[shift] = order[shift-1] }; order[0] = page }
			} else if last_request[page] >= 0 {
				for target in 0 .. position {
					candidate := order[target]; mut occurrences := 0
					for t := last_request[page]+1; t < time; t++ { if request_ids[t] == candidate { occurrences++ } }
					if occurrences <= 1 { for shift := position; shift > target; shift-- { order[shift] = order[shift-1] }; order[target] = page; break }
				}
			}
			last_request[page] = time
		}
		mut words := [1+2*max_n+max_requests]i64{}; words[0] = total_cost
		for i in 0 .. n { words[1+i] = i64(order[i]) }
		for i in 0 .. requests { words[1+n+i] = positions[i] }
		for i in 0 .. n { words[1+n+requests+i] = bits[i] }
		output_bytes := 8*(1+2*n+requests)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		for word in 0 .. 1+2*n+requests { put_i64_le(mut staged[0], 8*word, words[word]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
