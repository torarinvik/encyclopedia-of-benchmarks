package create_binary_tree_from_inorder_preorder

import "core:c"

MAX_NODES :: 63
MAX_OUTPUT :: 6 * MAX_NODES + 1

@(export)
create_binary_tree_from_inorder_preorder :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || values[0] < 0 || values[0] > MAX_NODES do return -1
	count := int(values[0])
	if int(length) != 1 + 2 * count do return -1
	for i := 0; i < count; i += 1 {
		pre, inorder := values[1 + i], values[1 + count + i]
		if pre < -2147483648 || pre > 2147483647 || inorder < -2147483648 || inorder > 2147483647 do return -1
		for j := 0; j < i; j += 1 do if pre == values[1 + j] || inorder == values[1 + count + j] do return -1
		matches := 0
		for j := 0; j < count; j += 1 do if pre == values[1 + count + j] do matches += 1
		if matches != 1 do return -1
	}
	left_child: [MAX_NODES]int
	right_child: [MAX_NODES]int
	for i := 0; i < count; i += 1 { left_child[i] = -1; right_child[i] = -1 }
	task_pre: [MAX_NODES]int
	task_in: [MAX_NODES]int
	task_size: [MAX_NODES]int
	task_count := 0
	if count > 0 { task_pre[0] = 0; task_in[0] = 0; task_size[0] = count; task_count = 1 }
	for task_count > 0 {
		task_count -= 1
		pre_start, in_start, size := task_pre[task_count], task_in[task_count], task_size[task_count]
		if size <= 0 || pre_start + size > count || in_start + size > count do return -1
		root_position := -1
		for i := in_start; i < in_start + size; i += 1 { if values[1 + i] == values[1 + count + pre_start] { root_position = i; break } }
		if root_position < 0 do return -1
		left_size := root_position - in_start
		right_size := size - left_size - 1
		if left_size > 0 do left_child[pre_start] = pre_start + 1
		if right_size > 0 do right_child[pre_start] = pre_start + left_size + 1
		if right_size > 0 { task_pre[task_count] = pre_start + left_size + 1; task_in[task_count] = root_position + 1; task_size[task_count] = right_size; task_count += 1 }
		if left_size > 0 { task_pre[task_count] = pre_start + 1; task_in[task_count] = in_start; task_size[task_count] = left_size; task_count += 1 }
	}
	required := 6 * count + 1
	if output == nil || output_capacity < c.size_t(required) do return -2
	encoded: [MAX_OUTPUT]u8
	pending: [2 * MAX_NODES + 1]int
	top := 1
	if count == 0 { pending[0] = -1 } else { pending[0] = 0 }
	written := 0
	for top > 0 {
		top -= 1
		node := pending[top]
		if node < 0 { encoded[written] = 0; written += 1 }
		else {
			value := values[1 + node]
			encoded[written] = 1; written += 1
			for byte := 0; byte < 4; byte += 1 {
				rem := value % 256
				if rem < 0 { rem += 256 }
				encoded[written] = u8(rem); written += 1
				value = (value - rem) / 256
			}
			pending[top] = right_child[node]; top += 1
			pending[top] = left_child[node]; top += 1
		}
	}
	for i := 0; i < written; i += 1 do output[i] = encoded[i]
	return i64(count)
}
