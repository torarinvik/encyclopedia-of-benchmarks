package randomized_marking_page_caching

import "core:c"

MAX_REQUESTS :: 32
MAX_PAGES :: 16
MAX_INPUT :: 67
MAX_OUTPUT_BYTES :: 536

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
randomized_marking_page_caching :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	cache_raw, requests_raw := input[0], input[1]
	if cache_raw < 1 || cache_raw > 8 || requests_raw < 0 || requests_raw > MAX_REQUESTS do return -1
	cache_size, requests := int(cache_raw), int(requests_raw)
	if length < c.size_t(3+requests) do return -1
	choices_raw := input[2+requests]
	if choices_raw < 0 || choices_raw > requests_raw || length != c.size_t(3+requests+int(choices_raw)) do return -1
	choice_count := int(choices_raw)
	pages: [MAX_REQUESTS]int = {}
	choices: [MAX_REQUESTS]int = {}
	for i := 0; i < requests; i += 1 {
		page := input[2+i]
		if page < 0 || page >= MAX_PAGES do return -1
		pages[i] = int(page)
	}
	for i := 0; i < choice_count; i += 1 {
		choice := input[3+requests+i]
		if choice < 0 || choice > MAX_PAGES do return -1
		choices[i] = int(choice)
	}
	resident: [MAX_PAGES]bool = {}
	marked: [MAX_PAGES]bool = {}
	hits: [MAX_REQUESTS]i64 = {}
	victims: [MAX_REQUESTS]i64 = {}
	for i := 0; i < MAX_REQUESTS; i += 1 { victims[i] = -1 }
	resident_count, choice_at := 0, 0
	misses: i64 = 0
	for request := 0; request < requests; request += 1 {
		page := pages[request]
		if resident[page] { hits[request] = 1; marked[page] = true; continue }
		misses += 1
		if resident_count == cache_size {
			eligible: [MAX_PAGES]int = {}
			eligible_count := 0
			for candidate := 0; candidate < MAX_PAGES; candidate += 1 {
				if resident[candidate] && !marked[candidate] { eligible[eligible_count] = candidate; eligible_count += 1 }
			}
			if eligible_count == 0 {
				for candidate := 0; candidate < MAX_PAGES; candidate += 1 {
					if resident[candidate] { marked[candidate] = false; eligible[eligible_count] = candidate; eligible_count += 1 }
				}
			}
			if choice_at >= choice_count || choices[choice_at] >= eligible_count do return -1
			victim := eligible[choices[choice_at]]
			choice_at += 1
			resident[victim] = false; marked[victim] = false; resident_count -= 1; victims[request] = i64(victim)
		}
		resident[page] = true; marked[page] = true; resident_count += 1
	}
	if choice_at != choice_count do return -1
	resident_mask, marked_mask: i64 = 0, 0
	for page := 0; page < MAX_PAGES; page += 1 {
		if resident[page] { resident_mask |= i64(1) << page }
		if resident[page] && marked[page] { marked_mask |= i64(1) << page }
	}
	words: [3+2*MAX_REQUESTS]i64 = {}
	words[0], words[1], words[2] = misses, resident_mask, marked_mask
	for i := 0; i < requests; i += 1 { words[3+i] = hits[i]; words[3+requests+i] = victims[i] }
	output_bytes := 8*(3+2*requests)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	for word := 0; word < 3+2*requests; word += 1 { store_i64_le(&staged[0], 8*word, words[word]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
