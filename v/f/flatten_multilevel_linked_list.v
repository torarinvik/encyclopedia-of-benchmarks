module flatten_multilevel_linked_list

const max_lists = 8
const max_chain_length = 8
const max_total_values = max_lists * max_chain_length
const max_input_length = 1 + max_lists * (1 + max_chain_length)

fn merge_recursive(left []i64, right []i64, mut output []i64,
		left_index int, right_index int, output_index int) int {
	if left_index == left.len {
		remaining := right.len - right_index
		for i in 0 .. remaining { output[output_index + i] = right[right_index + i] }
		return output_index + remaining
	}
	if right_index == right.len {
		remaining := left.len - left_index
		for i in 0 .. remaining { output[output_index + i] = left[left_index + i] }
		return output_index + remaining
	}
	if left[left_index] < right[right_index] {
		output[output_index] = left[left_index]
		return merge_recursive(left, right, mut output, left_index + 1, right_index, output_index + 1)
	}
	output[output_index] = right[right_index]
	return merge_recursive(left, right, mut output, left_index, right_index + 1, output_index + 1)
}

fn flatten_suffix(lists []i64, lengths []int, count int, index int, mut output []i64) int {
	row := index * max_chain_length
	if index + 1 == count {
		for i in 0 .. lengths[index] { output[i] = lists[row + i] }
		return lengths[index]
	}
	mut suffix := []i64{len: max_total_values, init: 0}
	suffix_length := flatten_suffix(lists, lengths, count, index + 1, mut suffix)
	left := lists[row..row + lengths[index]]
	return merge_recursive(left, suffix[..suffix_length], mut output, 0, 0, 0)
}

fn store_i64(mut output []u8, offset usize, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) }
}

@[export: 'flatten_multilevel_linked_list']
pub fn flatten_multilevel_linked_list(values &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length < 1 || length > max_input_length { return -1 }
	list_count_value := unsafe { values[0] }
	if list_count_value < 0 || list_count_value > max_lists { return -1 }
	count := int(list_count_value)
	if count == 0 { return if length == 1 { 0 } else { -1 } }

	mut lists := []i64{len: max_lists * max_chain_length, init: 0}
	mut lengths := []int{len: max_lists, init: 0}
	mut total := 0
	mut cursor := 1
	for list in 0 .. count {
		if cursor >= length { return -1 }
		chain_length_value := unsafe { values[cursor] }
		if chain_length_value < 1 || chain_length_value > max_chain_length { return -1 }
		chain_length := int(chain_length_value)
		cursor++
		if chain_length > length - cursor { return -1 }
		lengths[list] = chain_length
		row := list * max_chain_length
		for item in 0 .. chain_length {
			value := unsafe { values[cursor] }
			cursor++
			if value < -1000 || value > 1000 ||
				(item > 0 && value < lists[row + item - 1]) { return -1 }
			lists[row + item] = value
		}
		total += chain_length
	}
	if cursor != length { return -1 }
	required := usize(total * 8)
	if capacity < required || unsafe { output == nil } { return -2 }

	mut flattened := []i64{len: max_total_values, init: 0}
	flatten_suffix(lists, lengths, count, 0, mut flattened)
	unsafe {
		for i in 0 .. total { store_i64(mut output[..], 8 * usize(i), flattened[i]) }
	}
	return i64(total)
}
