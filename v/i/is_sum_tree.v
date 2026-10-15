const max_nodes = 400
const invalid_result = i64(-9000000000000000000)

fn subtree_sum(nodes &i64, index i64) i64 {
	if index < 0 { return 0 }
	base := int(index) * 3
	return unsafe { nodes[base] + subtree_sum(nodes, unsafe { nodes[base+1] }) + subtree_sum(nodes, unsafe { nodes[base+2] }) }
}
fn check_node(nodes &i64, index i64) bool {
	base := int(index) * 3
	value := unsafe { nodes[base] }; left := unsafe { nodes[base+1] }; right := unsafe { nodes[base+2] }
	if left == -1 && right == -1 { return true }
	left_sum := subtree_sum(nodes,left); right_sum := subtree_sum(nodes,right)
	left_ok := left == -1 || check_node(nodes,left); right_ok := right == -1 || check_node(nodes,right)
	return value == left_sum + right_sum && left_ok && right_ok
}

@[export: 'is_sum_tree']
pub fn is_sum_tree(nodes &i64, count usize, root i64) i64 {
	if unsafe { nodes == nil } || count == 0 || count > max_nodes || root < 0 || u64(root) >= u64(count) { return invalid_result }
	mut seen := [max_nodes]bool{}
	mut stack := [max_nodes * 2]i64{}
	mut top := 0
	stack[top] = root; top++
	for top > 0 {
		top--; index := stack[top]
		if index < 0 || u64(index) >= u64(count) || seen[int(index)] { return invalid_result }
		seen[int(index)] = true; base := int(index) * 3
		value := unsafe { nodes[base] }; left := unsafe { nodes[base+1] }; right := unsafe { nodes[base+2] }
		if value < -1_000_000_000 || value > 1_000_000_000 || left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(count)) || (right >= 0 && u64(right) >= u64(count)) { return invalid_result }
		if left >= 0 { stack[top] = left; top++ }
		if right >= 0 { stack[top] = right; top++ }
	}
	if check_node(nodes,root) { return 1 }
	return 0
}
