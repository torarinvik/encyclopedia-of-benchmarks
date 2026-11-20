package t_threshold_three_sorted_lists

import "core:c"

LISTS :: 3
MAX_LIST :: 32
MAX_VALUES :: 48
MAX_INPUT :: 3 + LISTS * MAX_LIST
WHITE :: 0
GREEN :: 1
RED :: 2

tt_put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
t_threshold_three_sorted_lists :: proc "c"(input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > MAX_INPUT + 1 do return -1
	var base, sizes: [LISTS]int
	at := 0
	for id := 0; id < LISTS; id += 1 {
		if at >= int(length) || input[at] < 1 || input[at] > MAX_LIST do return -1
		sizes[id] = int(input[at]); at += 1
		if sizes[id] > int(length) - at do return -1
		base[id] = at
		for j := 0; j < sizes[id]; j += 1 {
			value := input[at + j]
			if value < -2147483648 || value > 2147483647 || (j > 0 && input[at + j - 1] >= value) do return -1
		}
		at += sizes[id]
	}
	if at != int(length) do return -1
	var tails, firsts: [LISTS]i64
	for i := 0; i < LISTS; i += 1 {
		tails[i] = input[base[i] + sizes[i] - 1]
		firsts[i] = input[base[i]]
	}
	for i := 0; i < LISTS; i += 1 {
		for j := i + 1; j < LISTS; j += 1 {
			if tails[i] > tails[j] { tails[i], tails[j] = tails[j], tails[i] }
			if firsts[i] > firsts[j] { firsts[i], firsts[j] = firsts[j], firsts[i] }
		}
	}
	maximum_candidate := tails[1]
	candidate := firsts[1]
	var color: [LISTS]int
	var cursor, search_base, search_low, search_step, search_probe, representative: [LISTS]int
	var representative_present: [LISTS]bool
	for i := 0; i < LISTS; i += 1 {
		cursor[i], search_base[i], search_low[i], search_step[i], search_probe[i] = 1, 1, 1, 1, 1
		if input[base[i]] == candidate { color[i] = GREEN }
		if input[base[i]] > candidate {
			color[i] = RED
			representative_present[i] = true
		}
	}
	var result: [MAX_VALUES]i64
	result_count, round_robin := 0, 0
	for candidate <= maximum_candidate {
		green_count, red_count, white_count := 0, 0, 0
		for i := 0; i < LISTS; i += 1 {
			if color[i] == GREEN { green_count++ }
			else if color[i] == RED { red_count++ }
			else { white_count++ }
		}
		if green_count >= 2 || red_count >= 2 {
			if green_count >= 2 { result[result_count] = candidate; result_count++ }
			recolor_count := 0
			if white_count == 0 { recolor_count = 1 }
			for i := 0; i < LISTS && recolor_count > 0; i += 1 {
				if color[i] != GREEN { continue }
				color[i] = WHITE
				search_base[i], search_low[i], search_probe[i], search_step[i] = cursor[i], cursor[i], cursor[i], 1
				recolor_count--
			}
			for i := 0; i < LISTS; i += 1 {
				if color[i] != GREEN { continue }
				color[i] = RED
				representative[i] = cursor[i]
				representative_present[i] = cursor[i] < sizes[i]
			}
			found := false
			next_candidate := i64(9223372036854775807)
			for i := 0; i < LISTS; i += 1 {
				if !representative_present[i] { continue }
				value := input[base[i] + representative[i]]
				if !found || value < next_candidate { found = true; next_candidate = value }
			}
			if !found { break }
			candidate = next_candidate
			for i := 0; i < LISTS; i += 1 {
				if color[i] != RED || !representative_present[i] || input[base[i] + representative[i]] != candidate { continue }
				color[i] = GREEN
				representative_present[i] = false
				cursor[i] = representative[i] + 1
				search_base[i], search_low[i], search_probe[i], search_step[i] = cursor[i], cursor[i], cursor[i], 1
			}
			continue
		}
		list_id := LISTS
		for offset := 0; offset < LISTS; offset += 1 {
			i := (round_robin + offset) % LISTS
			if color[i] == WHITE { list_id = i; break }
		}
		if list_id == LISTS { break }
		round_robin = (list_id + 1) % LISTS
		probe := search_probe[list_id]
		if probe >= sizes[list_id] { probe = sizes[list_id] - 1 }
		if input[base[list_id] + probe] < candidate {
			search_low[list_id] = probe + 1
			if probe + 1 == sizes[list_id] {
				color[list_id] = RED
				representative[list_id] = sizes[list_id]
				representative_present[list_id] = false
			} else {
				search_step[list_id] *= 2
				next_probe := search_base[list_id] + search_step[list_id] - 1
				if next_probe < sizes[list_id] { search_probe[list_id] = next_probe }
				else { search_probe[list_id] = sizes[list_id] - 1 }
			}
			continue
		}
		low, high := search_low[list_id], probe + 1
		for low < high {
			middle := low + (high - low) / 2
			if input[base[list_id] + middle] < candidate { low = middle + 1 }
			else { high = middle }
		}
		if low < sizes[list_id] && input[base[list_id] + low] == candidate {
			color[list_id] = GREEN
			cursor[list_id] = low + 1
		} else {
			color[list_id] = RED
			representative[list_id] = low
			representative_present[list_id] = low < sizes[list_id]
		}
	}
	output_bytes := 8 * (1 + result_count)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	tt_put_i64_le(output, 0, i64(result_count))
	for i := 0; i < result_count; i += 1 { tt_put_i64_le(output, 8*(i+1), result[i]) }
	return i64(output_bytes)
}
