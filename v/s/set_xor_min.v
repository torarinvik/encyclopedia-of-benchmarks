module set_xor_min

const max_q = 64
const max_bits = 30
const max_nodes = 1 + max_bits * max_q
const max_input_values = 1 + 2 * max_q
const value_limit = i64(1) << max_bits

fn find_or_create_child(mut children []int, mut node_count int, node int, direction int) int {
	slot := node * 2 + direction
	mut child := children[slot]
	if child < 0 {
		child = node_count
		node_count++
		children[child * 2] = -1
		children[child * 2 + 1] = -1
		children[slot] = child
	}
	return child
}

fn insert_value(mut children []int, mut count []int, mut node_count int, value u32) {
	mut path := []int{len: max_bits + 1}
	mut node := 0
	for depth in 0 .. max_bits {
		bit := max_bits - 1 - depth
		direction := int((value >> bit) & 1)
		node = find_or_create_child(mut children, mut node_count, node, direction)
		path[depth + 1] = node
	}
	if count[node] != 0 {
		return
	}
	for item in path {
		count[item]++
	}
}

fn remove_value(children []int, mut count []int, value u32) {
	mut path := []int{len: max_bits + 1}
	mut node := 0
	for depth in 0 .. max_bits {
		bit := max_bits - 1 - depth
		direction := int((value >> bit) & 1)
		node = children[node * 2 + direction]
		if node < 0 {
			return
		}
		path[depth + 1] = node
	}
	if count[node] == 0 {
		return
	}
	for item in path {
		count[item]--
	}
}

fn minimum_xor(children []int, count []int, value u32) u32 {
	mut node := 0
	mut result := u32(0)
	for bit := max_bits - 1; bit >= 0; bit-- {
		preferred := int((value >> bit) & 1)
		child := children[node * 2 + preferred]
		if child >= 0 && count[child] > 0 {
			node = child
		} else {
			result |= u32(1) << bit
			node = children[node * 2 + (preferred ^ 1)]
		}
	}
	return result
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'set_xor_min']
pub fn set_xor_min(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_values {
		return -1
	}
	q_value := unsafe { input[0] }
	if q_value < 1 || q_value > max_q {
		return -1
	}
	q := int(q_value)
	if length != usize(1 + 2 * q) {
		return -1
	}
	for operation in 0 .. q {
		offset := 1 + 2 * operation
		kind := unsafe { input[offset] }
		value := unsafe { input[offset + 1] }
		if kind < 0 || kind > 2 || value < 0 || value >= value_limit {
			return -1
		}
	}

	mut children := []int{len: max_nodes * 2, init: -1}
	mut count := []int{len: max_nodes}
	mut node_count := 1
	mut answers := []i64{len: max_q}
	mut answer_count := 0
	for operation in 0 .. q {
		offset := 1 + 2 * operation
		kind := unsafe { input[offset] }
		value := u32(unsafe { input[offset + 1] })
		if kind == 0 {
			insert_value(mut children, mut count, mut node_count, value)
		} else if kind == 1 {
			remove_value(children, mut count, value)
		} else {
			if count[0] == 0 {
				return -1
			}
			answers[answer_count] = i64(minimum_xor(children, count, value))
			answer_count++
		}
	}

	required := 8 * answer_count
	if unsafe { output == nil } || capacity < usize(required) {
		return -2
	}
	for index in 0 .. answer_count {
		store_i64_le(mut output, 8 * index, answers[index])
	}
	return i64(required)
}
