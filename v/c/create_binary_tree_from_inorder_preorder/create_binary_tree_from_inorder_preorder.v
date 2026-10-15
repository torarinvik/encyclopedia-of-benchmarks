module create_binary_tree_from_inorder_preorder

const max_nodes = 63
const max_output = 6 * max_nodes + 1

@[export: 'create_binary_tree_from_inorder_preorder']
pub fn create_binary_tree_from_inorder_preorder(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 1 { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 0 || count_value > max_nodes { return -1 }
	count := int(count_value)
	if int(length) != 1 + 2 * count { return -1 }
	unsafe {
		for i in 0 .. count {
			pre := values[1 + i]
			inorder := values[1 + count + i]
			if pre < -2147483648 || pre > 2147483647 || inorder < -2147483648 || inorder > 2147483647 { return -1 }
			for j in 0 .. i { if pre == values[1 + j] || inorder == values[1 + count + j] { return -1 } }
			mut matches := 0
			for j in 0 .. count { if pre == values[1 + count + j] { matches++ } }
			if matches != 1 { return -1 }
		}
		mut left_child := [max_nodes]int{}
		mut right_child := [max_nodes]int{}
		for i in 0 .. count { left_child[i] = -1; right_child[i] = -1 }
		mut task_pre := [max_nodes]int{}
		mut task_in := [max_nodes]int{}
		mut task_size := [max_nodes]int{}
		mut task_count := 0
		if count > 0 { task_pre[0] = 0; task_in[0] = 0; task_size[0] = count; task_count = 1 }
		for task_count > 0 {
			task_count--
			pre_start, in_start, size := task_pre[task_count], task_in[task_count], task_size[task_count]
			if size <= 0 || pre_start + size > count || in_start + size > count { return -1 }
			mut root_position := -1
			for i in in_start .. in_start + size { if values[1 + i] == values[1 + count + pre_start] { root_position = i; break } }
			if root_position < 0 { return -1 }
			left_size := root_position - in_start
			right_size := size - left_size - 1
			if left_size > 0 { left_child[pre_start] = pre_start + 1 }
			if right_size > 0 { right_child[pre_start] = pre_start + left_size + 1 }
			if right_size > 0 { task_pre[task_count] = pre_start + left_size + 1; task_in[task_count] = root_position + 1; task_size[task_count] = right_size; task_count++ }
			if left_size > 0 { task_pre[task_count] = pre_start + 1; task_in[task_count] = in_start; task_size[task_count] = left_size; task_count++ }
		}
		required := 6 * count + 1
		if output == nil || output_capacity < usize(required) { return -2 }
		mut encoded := [max_output]u8{}
		mut pending := [2 * max_nodes + 1]int{}
		mut top := 1
		if count == 0 { pending[0] = -1 } else { pending[0] = 0 }
		mut written := 0
		for top > 0 {
			top--
			node := pending[top]
			if node < 0 { encoded[written] = 0; written++ }
			else {
				mut value := values[1 + node]
				encoded[written] = 1; written++
				for _ in 0 .. 4 {
					mut rem := value % 256
					if rem < 0 { rem += 256 }
					encoded[written] = u8(rem); written++
					value = (value - rem) / 256
				}
				pending[top] = right_child[node]; top++
				pending[top] = left_child[node]; top++
			}
		}
		for i in 0 .. written { output[i] = encoded[i] }
		return i64(count)
	}
}
