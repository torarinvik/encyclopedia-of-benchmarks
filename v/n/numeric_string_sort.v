module numeric_string_sort

const max_items = 64
const max_token_length = 32
const max_input_length = 2113
const max_output_length = 2111

fn token_less(values &i64, left_start usize, left_length usize,
			  right_start usize, right_length usize) bool {
	unsafe {
		if left_length != right_length { return left_length < right_length }
		for index in 0 .. int(left_length) {
			left := values[int(left_start) + index]
			right := values[int(right_start) + index]
			if left != right { return left < right }
		}
	}
	return false
}

// Sort bounded decimal tokens by normalized length, then lexicographically.
@[export: 'numeric_string_sort']
pub fn numeric_string_sort(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length == 0 || length > max_input_length + 1 { return -1 }
		if values[0] < 0 || values[0] > max_items { return -1 }
		count := usize(values[0])
		mut starts := [max_items]usize{}
		mut token_lengths := [max_items]usize{}
		mut normalized_starts := [max_items]usize{}
		mut normalized_lengths := [max_items]usize{}
		mut order := [max_items]usize{}
		mut cursor := usize(1)
		mut output_length := usize(0)
		if count > 0 { output_length = count - 1 }

		for item in 0 .. int(count) {
			if cursor >= length { return -1 }
			raw_length := values[int(cursor)]
			cursor++
			if raw_length < 1 || raw_length > max_token_length { return -1 }
			token_length := usize(raw_length)
			if token_length > length - cursor { return -1 }
			start := cursor
			for offset in 0 .. int(token_length) {
				if values[int(start) + offset] < i64(`0`) || values[int(start) + offset] > i64(`9`) { return -1 }
			}
			mut zeros := usize(0)
			for zeros < token_length && values[int(start + zeros)] == i64(`0`) { zeros++ }
			starts[item] = start
			token_lengths[item] = token_length
			normalized_starts[item] = start + zeros
			normalized_lengths[item] = token_length - zeros
			for previous in 0 .. item {
				if normalized_lengths[previous] != normalized_lengths[item] { continue }
				mut equal := true
				for offset in 0 .. int(normalized_lengths[item]) {
					if values[int(normalized_starts[previous]) + offset] != values[int(normalized_starts[item]) + offset] {
						equal = false
						break
					}
				}
				if equal {
					if token_lengths[previous] != token_length { return -1 }
					for offset in 0 .. int(token_length) {
						if values[int(starts[previous]) + offset] != values[int(start) + offset] { return -1 }
					}
				}
			}
			output_length += token_length
			cursor += token_length
			order[item] = usize(item)
		}
		if cursor != length || output_length > max_output_length { return -1 }

		for item in 1 .. int(count) {
			key := order[item]
			mut position := usize(item)
			for position > 0 && token_less(values, normalized_starts[key], normalized_lengths[key],
											 normalized_starts[order[position - 1]], normalized_lengths[order[position - 1]]) {
				order[position] = order[position - 1]
				position--
			}
			order[position] = key
		}
		if output == nil && output_length != 0 || output_capacity < output_length { return -2 }
		mut written := usize(0)
		for item in 0 .. int(count) {
			if item > 0 { output[int(written)] = u8(` `); written++ }
			index := order[item]
			for offset in 0 .. int(token_lengths[index]) {
				output[int(written)] = u8(values[int(starts[index]) + offset])
				written++
			}
		}
		return i64(output_length)
	}
}
