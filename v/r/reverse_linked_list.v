module reverse_linked_list

const max_n = 256

@[export: 'reverse_linked_list']
pub fn reverse_linked_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > max_n + 1 { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(n + 1) { return -1 }
	output_bytes := 8 * n
	if output == nil || capacity < usize(output_bytes) { return -2 }

	mut nodes := [max_n]i64{}
	mut next := [max_n]int{}
	mut previous_link := [max_n]int{}
	for i in 0 .. n {
		unsafe { nodes[i] = input[i + 1] }
		next[i] = if i + 1 < n { i + 1 } else { -1 }
		previous_link[i] = if i > 0 { i - 1 } else { -1 }
	}
	mut previous := -1
	mut current := 0
	for current >= 0 {
		next_node := next[current]
		next[current] = previous
		previous_link[current] = next_node
		previous = current
		current = next_node
	}
	mut node := previous
	mut expected_previous := -1
	mut result := [max_n]i64{}
	for i in 0 .. n {
		if node < 0 || previous_link[node] != expected_previous { return -1 }
		result[i] = nodes[node]
		expected_previous = node
		node = next[node]
	}
	if node >= 0 { return -1 }
	for i in 0 .. n {
		bits := u64(result[i])
		for byte in 0 .. 8 {
			unsafe { output[i*8+byte] = u8((bits >> (8*byte)) & 255) }
		}
	}
	return i64(output_bytes)
}
