module randomized_marking_page_caching

import core.c

const (
	max_requests = 32
	max_pages = 16
	max_input = 67
	max_output_bytes = 536
)

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'randomized_marking_page_caching']
pub fn randomized_marking_page_caching(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		cache_raw := input[0]
		requests_raw := input[1]
		if cache_raw < 1 || cache_raw > 8 || requests_raw < 0 || requests_raw > max_requests { return -1 }
		cache_size := int(cache_raw)
		requests := int(requests_raw)
		if length < usize(3 + requests) { return -1 }
		choices_raw := input[2 + requests]
		if choices_raw < 0 || choices_raw > requests_raw || length != usize(3 + requests + int(choices_raw)) { return -1 }
		choice_count := int(choices_raw)
		mut pages := [max_requests]int{}
		mut choices := [max_requests]int{}
		for i in 0 .. requests {
			page := input[2 + i]
			if page < 0 || page >= max_pages { return -1 }
			pages[i] = int(page)
		}
		for i in 0 .. choice_count {
			choice := input[3 + requests + i]
			if choice < 0 || choice > max_pages { return -1 }
			choices[i] = int(choice)
		}
		mut resident := [max_pages]bool{}
		mut marked := [max_pages]bool{}
		mut hits := [max_requests]i64{}
		mut victims := [max_requests]i64{}
		for i in 0 .. max_requests { victims[i] = -1 }
		mut resident_count := 0
		mut choice_at := 0
		mut misses := i64(0)
		for request in 0 .. requests {
			page := pages[request]
			if resident[page] { hits[request] = 1; marked[page] = true; continue }
			misses++
			if resident_count == cache_size {
				mut eligible := [max_pages]int{}
				mut eligible_count := 0
				for candidate in 0 .. max_pages {
					if resident[candidate] && !marked[candidate] { eligible[eligible_count] = candidate; eligible_count++ }
				}
				if eligible_count == 0 {
					for candidate in 0 .. max_pages {
						if resident[candidate] { marked[candidate] = false; eligible[eligible_count] = candidate; eligible_count++ }
					}
				}
				if choice_at >= choice_count || choices[choice_at] >= eligible_count { return -1 }
				victim := eligible[choices[choice_at]]
				choice_at++
				resident[victim] = false; marked[victim] = false; resident_count--; victims[request] = i64(victim)
			}
			resident[page] = true; marked[page] = true; resident_count++
		}
		if choice_at != choice_count { return -1 }
		mut resident_mask := i64(0)
		mut marked_mask := i64(0)
		for page in 0 .. max_pages {
			if resident[page] { resident_mask |= i64(1) << page }
			if resident[page] && marked[page] { marked_mask |= i64(1) << page }
		}
		mut words := [3 + 2 * max_requests]i64{}
		words[0] = misses; words[1] = resident_mask; words[2] = marked_mask
		for i in 0 .. requests { words[3 + i] = hits[i]; words[3 + requests + i] = victims[i] }
		output_bytes := 8 * (3 + 2 * requests)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		for word in 0 .. 3 + 2 * requests { put_i64_le(mut staged[0], 8 * word, words[word]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
