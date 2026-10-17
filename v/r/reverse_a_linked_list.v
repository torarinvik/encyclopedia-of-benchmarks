module reverse_a_linked_list

const max_n = 128

@[export: 'reverse_a_linked_list']
pub fn reverse_a_linked_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > max_n + 1 { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 0 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(n + 1) { return -1 }
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	output_bytes := 4 * n
	if output == nil || capacity < usize(output_bytes) { return -2 }

	mut nodes := [max_n]i32{}
	mut next := [max_n]int{}
	mut head := -1
	for i in 0 .. n {
		unsafe { nodes[i] = i32(input[i + 1]) }
		next[i] = -1
		if head < 0 { head = i }
		else {
			mut tail := head
			for next[tail] >= 0 { tail = next[tail] }
			next[tail] = i
		}
	}
	mut previous := -1
	mut current := head
	for current >= 0 {
		next_node := next[current]
		next[current] = previous
		previous = current
		current = next_node
	}
	head = previous
	for index in 0 .. n {
		mut node := head
		for step in 0 .. index { node = next[node] }
		bits := u32(nodes[node])
		for byte in 0 .. 4 {
			unsafe { output[index*4+byte] = u8((bits >> (8*byte)) & 255) }
		}
	}
	return i64(output_bytes)
}
