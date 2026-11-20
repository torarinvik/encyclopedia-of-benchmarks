fn tt_put_i64_le(output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 't_threshold_three_sorted_lists']
pub fn t_threshold_three_sorted_lists(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > 100 { return -1 }
		mut base := [3]int{}
		mut sizes := [3]int{}
		mut at := 0
		for id in 0 .. 3 {
			if at >= int(length) || input[at] < 1 || input[at] > 32 { return -1 }
			sizes[id] = int(input[at])
			at++
			if sizes[id] > int(length) - at { return -1 }
			base[id] = at
			for j in 0 .. sizes[id] {
				value := input[at + j]
				if value < -2147483648 || value > 2147483647 || (j > 0 && input[at + j - 1] >= value) { return -1 }
			}
			at += sizes[id]
		}
		if at != int(length) { return -1 }
		mut tails := [3]i64{}
		mut firsts := [3]i64{}
		for i in 0 .. 3 {
			tails[i] = input[base[i] + sizes[i] - 1]
			firsts[i] = input[base[i]]
		}
		for i in 0 .. 3 {
			for j in i + 1 .. 3 {
				if tails[i] > tails[j] { tails[i], tails[j] = tails[j], tails[i] }
				if firsts[i] > firsts[j] { firsts[i], firsts[j] = firsts[j], firsts[i] }
			}
		}
		maximum_candidate := tails[1]
		mut candidate := firsts[1]
		mut color := [3]int{}
		mut cursor := [3]int{}
		mut search_base := [3]int{}
		mut search_low := [3]int{}
		mut search_step := [3]int{}
		mut search_probe := [3]int{}
		mut representative := [3]int{}
		mut representative_present := [3]bool{}
		for i in 0 .. 3 {
			cursor[i], search_base[i], search_low[i], search_step[i], search_probe[i] = 1, 1, 1, 1, 1
			if input[base[i]] == candidate { color[i] = 1 }
			else if input[base[i]] > candidate { color[i] = 2; representative_present[i] = true }
		}
		mut result := [48]i64{}
		mut result_count := 0
		mut round_robin := 0
		for candidate <= maximum_candidate {
			mut green_count, mut red_count, mut white_count := 0, 0, 0
			for i in 0 .. 3 {
				if color[i] == 1 { green_count++ }
				else if color[i] == 2 { red_count++ }
				else { white_count++ }
			}
			if green_count >= 2 || red_count >= 2 {
				if green_count >= 2 { result[result_count] = candidate; result_count++ }
				mut recolor_count := 0
				if white_count == 0 { recolor_count = 1 }
				for i in 0 .. 3 {
					if recolor_count == 0 { break }
					if color[i] != 1 { continue }
					color[i] = 0
					search_base[i], search_low[i], search_step[i], search_probe[i] = cursor[i], cursor[i], 1, cursor[i]
					recolor_count--
				}
				for i in 0 .. 3 {
					if color[i] != 1 { continue }
					color[i] = 2
					representative[i] = cursor[i]
					representative_present[i] = cursor[i] < sizes[i]
				}
				mut found := false
				mut next_candidate := i64(9223372036854775807)
				for i in 0 .. 3 {
					if !representative_present[i] { continue }
					value := input[base[i] + representative[i]]
					if !found || value < next_candidate { found = true; next_candidate = value }
				}
				if !found { break }
				candidate = next_candidate
				for i in 0 .. 3 {
					if color[i] != 2 || !representative_present[i] || input[base[i] + representative[i]] != candidate { continue }
					color[i] = 1
					representative_present[i] = false
					cursor[i] = representative[i] + 1
					search_base[i], search_low[i], search_step[i], search_probe[i] = cursor[i], cursor[i], 1, cursor[i]
				}
				continue
			}
			mut list_id := 3
			for offset in 0 .. 3 {
				i := (round_robin + offset) % 3
				if color[i] == 0 { list_id = i; break }
			}
			if list_id == 3 { break }
			round_robin = (list_id + 1) % 3
			probe := search_probe[list_id]
			if probe >= sizes[list_id] { probe = sizes[list_id] - 1 }
			if input[base[list_id] + probe] < candidate {
				search_low[list_id] = probe + 1
				if probe + 1 == sizes[list_id] {
					color[list_id] = 2
					representative[list_id] = sizes[list_id]
					representative_present[list_id] = false
				} else {
					search_step[list_id] *= 2
					next_probe := search_base[list_id] + search_step[list_id] - 1
					search_probe[list_id] = if next_probe < sizes[list_id] { next_probe } else { sizes[list_id] - 1 }
				}
				continue
			}
			mut low, mut high := search_low[list_id], probe + 1
			for low < high {
				middle := low + (high - low) / 2
				if input[base[list_id] + middle] < candidate { low = middle + 1 }
				else { high = middle }
			}
			if low < sizes[list_id] && input[base[list_id] + low] == candidate {
				color[list_id] = 1
				cursor[list_id] = low + 1
			} else {
				color[list_id] = 2
				representative[list_id] = low
				representative_present[list_id] = low < sizes[list_id]
			}
		}
		output_bytes := 8 * (1 + result_count)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		tt_put_i64_le(output, 0, i64(result_count))
		for i in 0 .. result_count { tt_put_i64_le(output, 8 * (i + 1), result[i]) }
		return i64(output_bytes)
	}
}
