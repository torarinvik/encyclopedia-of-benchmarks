module length_limited_huffman_package_merge

const max_symbols = 12
const max_limit = 6
const max_levels = 16
const max_items = 32
const max_input_length = 15

fn solve(symbol_count int, limit int, input &i64) i64 {
	mut weights := [max_symbols]i64{}
	unsafe {
		for index in 0 .. symbol_count {
			weight := input[index + 2]
			if weight < 0 || weight > 1_000_000 { return -1 }
			weights[index] = weight
		}
	}
	for index in 1 .. symbol_count {
		key := weights[index]
		mut position := index
		for position > 0 && weights[position - 1] > key {
			weights[position] = weights[position - 1]
			position--
		}
		weights[position] = key
	}

	mut levels := [max_levels * max_items]i64{}
	mut counts := [max_levels]int{}
	for level in 0 .. limit {
		for index in 0 .. symbol_count { levels[level * max_items + index] = weights[index] }
		counts[level] = symbol_count
	}
	mut remaining := (i64(symbol_count - 1)) << limit
	mut total := i64(0)
	mut level := 0
	for remaining > 0 {
		for level < max_levels && counts[level] == 0 { level++ }
		if level >= max_levels { return -1 }
		width := i64(1) << level
		smallest_needed := remaining & -remaining
		if width > smallest_needed { return -1 }

		base := level * max_items
		mut current_count := counts[level]
		if width == smallest_needed {
			total += levels[base]
			for index in 1 .. current_count { levels[base + index - 1] = levels[base + index] }
			current_count--
			counts[level] = current_count
			remaining -= width
			if remaining == 0 { break }
		}

		mut packages := [max_items]i64{}
		mut package_count := 0
		mut index := 0
		for index + 1 < current_count {
			packages[package_count] = levels[base + index] + levels[base + index + 1]
			package_count++
			index += 2
		}
		counts[level] = 0

		next_level := level + 1
		if next_level >= max_levels { return -1 }
		existing_count := counts[next_level]
		mut merged := [max_items]i64{}
		mut package_index := 0
		mut existing_index := 0
		mut merged_count := 0
		for package_index < package_count && existing_index < existing_count {
			if packages[package_index] <= levels[next_level * max_items + existing_index] {
				merged[merged_count] = packages[package_index]
				package_index++
			} else {
				merged[merged_count] = levels[next_level * max_items + existing_index]
				existing_index++
			}
			merged_count++
		}
		for package_index < package_count {
			merged[merged_count] = packages[package_index]
			package_index++
			merged_count++
		}
		for existing_index < existing_count {
			merged[merged_count] = levels[next_level * max_items + existing_index]
			existing_index++
			merged_count++
		}
		for index in 0 .. merged_count { levels[next_level * max_items + index] = merged[index] }
		counts[next_level] = merged_count
		level = next_level
	}
	return total
}

export fn length_limited_huffman_package_merge(input_opt: ?[*]const i64, length: usize) i64 {
	if (input_opt == null || length < 4 || length > max_input_length) { return -1 }
	input := input_opt.?
	nv, lv := input[0], input[1]
	if nv < 2 || nv > max_symbols || lv < 1 || lv > max_limit { return -1 }
	symbol_count, limit := int(nv), int(lv)
	if symbol_count > (1 << limit) || length != symbol_count + 2 { return -1 }
	return solve(symbol_count, limit, input)
}
