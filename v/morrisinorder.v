module morrisinorder

const max_node_count = 63
const max_parseable_input_length = 65

fn store_i32_le(output &u8, offset int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'morrisinorder']
pub fn morrisinorder(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > usize(max_parseable_input_length) { return -1 }
		raw_count := values[0]
		if raw_count < 0 || raw_count > max_node_count { return -1 }
		count := int(raw_count)
		if length != usize(count + 1) { return -1 }
		for index in 0 .. count {
			node := values[index + 1]
			if node < -2147483648 || node > 2147483647 { return -1 }
		}

		byte_count := count * 4
		if output == nil || output_capacity < usize(byte_count) { return -2 }

		mut left_nodes := [max_node_count]int{}
		mut right_nodes := [max_node_count]int{}
		for index in 0 .. count {
			left_index := 2 * index + 1
			right_index := 2 * index + 2
			left_nodes[index] = if left_index < count { left_index } else { -1 }
			right_nodes[index] = if right_index < count { right_index } else { -1 }
		}

		mut current := if count == 0 { -1 } else { 0 }
		mut written := 0
		for current >= 0 {
			if left_nodes[current] < 0 {
				store_i32_le(output, written * 4, i32(values[current + 1]))
				written += 1
				current = right_nodes[current]
			} else {
				mut predecessor := left_nodes[current]
				for right_nodes[predecessor] >= 0 && right_nodes[predecessor] != current {
					predecessor = right_nodes[predecessor]
				}
				if right_nodes[predecessor] < 0 {
					right_nodes[predecessor] = current
					current = left_nodes[current]
				} else {
					right_nodes[predecessor] = -1
					store_i32_le(output, written * 4, i32(values[current + 1]))
					written += 1
					current = right_nodes[current]
				}
			}
		}
		return i64(byte_count)
	}
}
