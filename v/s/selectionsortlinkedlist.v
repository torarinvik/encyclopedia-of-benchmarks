module selectionsortlinkedlist

const max_count = 64
const max_input_length = 66

fn selection_sort_links(values []i32, mut next []int, mut head int) {
	mut minimum := head
	mut current := next[minimum]
	mut previous := minimum
	mut sorted_tail := -1
	for next[minimum] != -1 {
		for current != -1 {
			if values[current] < values[minimum] {
				if sorted_tail == -1 {
					if previous == minimum {
						head = current
						next[minimum] = next[current]
						next[current] = previous
						minimum = current
						current = next[previous]
					} else {
						head = current
						next[previous] = next[current]
						next[current] = minimum
						minimum = current
						current = next[previous]
					}
				} else {
					next[sorted_tail] = current
					next[previous] = next[current]
					next[current] = minimum
					minimum = current
					current = next[previous]
				}
			} else {
				previous = next[previous]
				current = next[current]
			}
		}
		sorted_tail = minimum
		minimum = next[minimum]
		previous = minimum
		current = next[minimum]
	}
}

fn write_i32_le(mut output &u8, offset int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'selectionsortlinkedlist']
pub fn selectionsortlinkedlist(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		raw_count := input[0]
		if raw_count < 1 || raw_count > i64(max_count) || int(length) != 1 + int(raw_count) { return -1 }
		count := int(raw_count)
		mut values := [max_count]i32{}
		mut next := [max_count]int{}
		for index in 0 .. count {
			value := input[index + 1]
			if value < -2147483648 || value > 2147483647 { return -1 }
			values[index] = i32(value)
			next[index] = if index + 1 < count { index + 1 } else { -1 }
		}
		byte_count := 4 * count
		if output == nil || int(output_capacity) < byte_count { return -2 }

		mut head := 0
		selection_sort_links(values[..], mut next[..], mut head)
		mut node := head
		for index in 0 .. count {
			write_i32_le(mut output, 4 * index, values[node])
			node = next[node]
		}
		return i64(byte_count)
	}
}
