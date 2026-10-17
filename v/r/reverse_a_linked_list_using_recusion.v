module reverse_a_linked_list_using_recusion

const max_n = 64

fn reverse_links(mut next []int, previous int, current int) int {
	if next[current] >= 0 {
		head := reverse_links(mut next, current, next[current])
		next[current] = previous
		next[previous] = -1
		return head
	}
	next[current] = previous
	next[previous] = -1
	return current
}

@[export: 'reverse_a_linked_list_using_recusion']
pub fn reverse_a_linked_list_using_recusion(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > max_n + 1 { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 2 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(n + 1) { return -1 }
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	bytes := 4 * n
	if output == nil || capacity < usize(bytes) { return -2 }

	mut nodes := [max_n]i32{}
	mut next := []int{len: max_n, init: -1}
	for i in 0 .. n {
		unsafe { nodes[i] = i32(input[i + 1]) }
		if i + 1 < n { next[i] = i + 1 }
	}
	mut node := reverse_links(mut next, 0, next[0])
	for i in 0 .. n {
		bits := u32(nodes[node])
		for byte in 0 .. 4 {
			unsafe { output[i * 4 + byte] = u8((bits >> (byte * 8)) & 255) }
		}
		if i + 1 < n { node = next[node] }
	}
	return i64(bytes)
}
