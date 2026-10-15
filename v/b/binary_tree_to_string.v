module binary_tree_to_string

const max_nodes = 127

fn decimal_length(value i64) usize {
	mut length := usize(0)
	mut magnitude := value
	if value < 0 { length = 1; magnitude = -value }
	for {
		length++
		magnitude /= 10
		if magnitude == 0 { break }
	}
	return length
}

fn append_value(value i32, mut output &u8, mut position &usize) {
	mut magnitude := i64(value)
	if value < 0 { output[position[0]] = u8(`-`); position[0]++; magnitude = -magnitude }
	mut digits := [10]u8{}
	mut count := 0
	for {
		digits[count] = u8(`0`) + u8(magnitude % 10)
		count++
		magnitude /= 10
		if magnitude == 0 { break }
	}
	for count > 0 {
		count--
		output[position[0]] = digits[count]
		position[0]++
	}
}

fn emit_node(values &i64, index int, mut output &u8, mut position &usize) {
	base := 2 + 3 * index
	unsafe {
		left := values[base + 1]
		right := values[base + 2]
		append_value(i32(values[base]), mut output, mut position)
		if left >= 0 {
			output[position[0]] = u8(`(`); position[0]++
			emit_node(values, int(left), mut output, mut position)
			output[position[0]] = u8(`)`); position[0]++
		} else if right >= 0 {
			output[position[0]] = u8(`(`); position[0]++
			output[position[0]] = u8(`)`); position[0]++
		}
		if right >= 0 {
			output[position[0]] = u8(`(`); position[0]++
			emit_node(values, int(right), mut output, mut position)
			output[position[0]] = u8(`)`); position[0]++
		}
	}
}

@[export: 'binary_tree_to_string']
pub fn binary_tree_to_string(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > i64(max_nodes) { return -1 }
		count := int(values[0])
		if length != usize(2 + 3 * count) { return -1 }
		root_value := values[1]
		if count == 0 { return if root_value == -1 { i64(0) } else { i64(-1) } }
		if root_value < 0 || root_value >= i64(count) { return -1 }
		root := int(root_value)
		mut parents := [max_nodes]u8{}
		mut seen := [max_nodes]bool{}
		mut stack := [max_nodes]int{}
		for i in 0 .. count {
			base := 2 + 3 * i
			value := values[base]
			left := values[base + 1]
			right := values[base + 2]
			if value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
				(left >= 0 && left >= i64(count)) || (right >= 0 && right >= i64(count)) { return -1 }
			if left >= 0 { parents[int(left)]++; if parents[int(left)] > 1 { return -1 } }
			if right >= 0 { parents[int(right)]++; if parents[int(right)] > 1 { return -1 } }
		}
		for i in 0 .. count {
			expected_parent_count := if i == root { u8(0) } else { u8(1) }
			if parents[i] != expected_parent_count { return -1 }
		}
		mut top := 1
		mut visited := 0
		stack[0] = root
		for top > 0 {
			top--
			index := stack[top]
			if seen[index] { return -1 }
			seen[index] = true
			visited++
			base := 2 + 3 * index
			left := values[base + 1]
			right := values[base + 2]
			if left >= 0 { stack[top] = int(left); top++ }
			if right >= 0 { stack[top] = int(right); top++ }
		}
		if visited != count { return -1 }
		mut required := usize(2 * (count - 1))
		for i in 0 .. count {
			base := 2 + 3 * i
			required += decimal_length(values[base])
			if values[base + 1] == -1 && values[base + 2] >= 0 { required += 2 }
		}
		if output_capacity < required { return -2 }
		mut position := usize(0)
		emit_node(values, root, mut output, mut position)
		return i64(position)
	}
}
