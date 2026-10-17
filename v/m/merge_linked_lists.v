module merge_linked_lists

const max_list_length = 32
const max_total_nodes = 2 * max_list_length
const max_parseable_input_length = 2 + max_total_nodes + 1

fn store_i64_le(mut output []u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@[export: 'merge_linked_lists']
pub fn merge_linked_lists(values &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length < 2 || length > max_parseable_input_length { return -1 }
	unsafe {
		raw_first := values[0]
		raw_second := values[1]
		if raw_first < 0 || raw_first > max_list_length || raw_second < 0 || raw_second > max_list_length { return -1 }
		first_length := int(raw_first)
		second_length := int(raw_second)
		total := first_length + second_length
		if total > max_total_nodes || int(length) != 2 + total { return -1 }

		mut node_values := [max_total_nodes]i64{}
		mut next := [max_total_nodes]int{}
		for index in 0 .. first_length {
			value := values[2 + index]
			if value < -2147483648 || value > 2147483647 { return -1 }
			node_values[index] = value
			next[index] = if index + 1 < first_length { index + 1 } else { -1 }
		}
		second_start := first_length
		for index in 0 .. second_length {
			value := values[2 + first_length + index]
			if value < -2147483648 || value > 2147483647 { return -1 }
			node := second_start + index
			node_values[node] = value
			next[node] = if index + 1 < second_length { node + 1 } else { -1 }
		}

		mut head1 := if first_length == 0 { -1 } else { 0 }
		head2 := if second_length == 0 { -1 } else { second_start }
		mut temp1 := head1
		mut temp2 := head2
		mut holder2 := -1
		for temp1 != -1 && temp2 != -1 {
			holder1 := next[temp1]
			next[temp1] = temp2
			if holder1 != -1 {
				holder2 = next[temp2]
				next[temp2] = holder1
			}
			temp1 = holder1
			temp2 = holder2
		}

		mut output_count := 0
		mut node := head1
		for node != -1 {
			if node < 0 || node >= total || output_count >= total { return -1 }
			output_count++
			node = next[node]
		}
		required := output_count * 8
		if output == nil || capacity < usize(required) { return -2 }

		node = head1
		for index in 0 .. output_count {
			store_i64_le(mut output[..], 8 * index, node_values[node])
			node = next[node]
		}
		return i64(required)
	}
}
