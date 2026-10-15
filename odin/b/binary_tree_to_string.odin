package binary_tree_to_string

import "core:c"

MAX_NODES :: 127

decimal_length :: proc "contextless" (value: i64) -> c.size_t {
	length := c.size_t(0)
	magnitude := value
	if value < 0 { length = 1; magnitude = -value }
	for {
		length += 1
		magnitude /= 10
		if magnitude == 0 do break
	}
	return length
}

append_value :: proc "contextless" (value: i32, output: [^]u8, position: ^c.size_t) {
	magnitude := i64(value)
	if value < 0 { output[position^] = u8('-'); position^ += 1; magnitude = -magnitude }
	digits: [10]u8
	count := 0
	for {
		digits[count] = u8('0') + u8(magnitude % 10)
		count += 1
		magnitude /= 10
		if magnitude == 0 do break
	}
	for count > 0 {
		count -= 1
		output[position^] = digits[count]
		position^ += 1
	}
}

emit_node :: proc "contextless" (values: [^]i64, index: int, output: [^]u8, position: ^c.size_t) {
	base := 2 + 3 * index
	left, right := values[base + 1], values[base + 2]
	append_value(i32(values[base]), output, position)
	if left >= 0 {
		output[position^] = u8('('); position^ += 1
		emit_node(values, int(left), output, position)
		output[position^] = u8(')'); position^ += 1
	} else if right >= 0 {
		output[position^] = u8('('); position^ += 1
		output[position^] = u8(')'); position^ += 1
	}
	if right >= 0 {
		output[position^] = u8('('); position^ += 1
		emit_node(values, int(right), output, position)
		output[position^] = u8(')'); position^ += 1
	}
}

@(export)
binary_tree_to_string :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || values[0] < 0 || values[0] > i64(MAX_NODES) do return -1
	count := int(values[0])
	if length != c.size_t(2 + 3 * count) do return -1
	root_value := values[1]
	if count == 0 { if root_value == -1 do return 0; return -1 }
	if root_value < 0 || root_value >= i64(count) do return -1
	root := int(root_value)
	parents: [MAX_NODES]u8
	seen: [MAX_NODES]bool
	stack: [MAX_NODES]int
	for i := 0; i < count; i += 1 {
		base := 2 + 3 * i
		value, left, right := values[base], values[base + 1], values[base + 2]
		if value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
			(left >= 0 && left >= i64(count)) || (right >= 0 && right >= i64(count)) { return -1 }
		if left >= 0 { parents[int(left)] += 1; if parents[int(left)] > 1 do return -1 }
		if right >= 0 { parents[int(right)] += 1; if parents[int(right)] > 1 do return -1 }
	}
	for i := 0; i < count; i += 1 {
		expected_parent_count := u8(1)
		if i == root do expected_parent_count = 0
		if parents[i] != expected_parent_count do return -1
	}
	top, visited := 1, 0
	stack[0] = root
	for top > 0 {
		top -= 1
		index := stack[top]
		if seen[index] do return -1
		seen[index] = true
		visited += 1
		base := 2 + 3 * index
		left, right := values[base + 1], values[base + 2]
		if left >= 0 { stack[top] = int(left); top += 1 }
		if right >= 0 { stack[top] = int(right); top += 1 }
	}
	if visited != count do return -1
	required := c.size_t(2 * (count - 1))
	for i := 0; i < count; i += 1 {
		base := 2 + 3 * i
		required += decimal_length(values[base])
		if values[base + 1] == -1 && values[base + 2] >= 0 do required += 2
	}
	if output == nil || output_capacity < required do return -2
	position := c.size_t(0)
	emit_node(values, root, output, &position)
	return i64(position)
}
