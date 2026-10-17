module rotate_singly_linked_lists

const max_n = 64

@[export: 'rotate_singly_linked_lists']
pub fn rotate_singly_linked_lists(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > max_n + 2 { return -1 }
	n_value := unsafe { input[0] }
	k := unsafe { input[1] }
	if n_value < 0 || n_value > max_n || k < 0 || k > 2147483647 { return -1 }
	n := int(n_value)
	if length != usize(n + 2) { return -1 }
	for i in 0 .. n {
		value := unsafe { input[i + 2] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	bytes := 8 * (n + 1)
	if output == nil || capacity < usize(bytes) { return -2 }

	mut nodes := [max_n]i32{}
	mut next := []int{len: max_n, init: -1}
	for i in 0 .. n {
		unsafe { nodes[i] = i32(input[i + 2]) }
		if i + 1 < n { next[i] = i + 1 }
	}
	mut head := -1
	if n > 0 { head = 0 }
	if n > 1 && k > 0 {
		tail := n - 1
		next[tail] = head
		shift := int(k % i64(n))
		steps := n - shift
		mut new_tail := tail
		for _ in 0 .. steps { new_tail = next[new_tail] }
		head = next[new_tail]
		next[new_tail] = -1
	}
	count := u64(n)
	for byte in 0 .. 8 {
		unsafe { output[byte] = u8((count >> (byte * 8)) & 255) }
	}
	mut node := head
	for i in 0 .. n {
		bits := u64(i64(nodes[node]))
		for byte in 0 .. 8 {
			unsafe { output[8 + i * 8 + byte] = u8((bits >> (byte * 8)) & 255) }
		}
		if i + 1 < n { node = next[node] }
	}
	return i64(bytes)
}
