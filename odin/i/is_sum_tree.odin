package is_sum_tree
import "core:c"

MAX_NODES :: 400
INVALID_RESULT :: i64 = -9_000_000_000_000_000_000

subtree_sum :: proc "contextless" (nodes: [^]i64, index: i64) -> i64 {
	if index < 0 do return 0
	base := int(index) * 3
	return nodes[base] + subtree_sum(nodes, nodes[base+1]) + subtree_sum(nodes, nodes[base+2])
}
check_node :: proc "contextless" (nodes: [^]i64, index: i64) -> bool {
	base := int(index) * 3; value := nodes[base]; left := nodes[base+1]; right := nodes[base+2]
	if left == -1 && right == -1 do return true
	left_sum := subtree_sum(nodes,left); right_sum := subtree_sum(nodes,right)
	left_ok := left == -1 || check_node(nodes,left); right_ok := right == -1 || check_node(nodes,right)
	return value == left_sum + right_sum && left_ok && right_ok
}

@(export)
is_sum_tree :: proc "c" (nodes: [^]i64, count: c.size_t, root: i64) -> i64 {
	if nodes == nil || count == 0 || count > MAX_NODES || root < 0 || u64(root) >= u64(count) do return INVALID_RESULT
	seen: [MAX_NODES]bool = {}; stack: [MAX_NODES*2]i64 = {}; top := 0
	stack[top] = root; top += 1
	for top > 0 {
		top -= 1; index := stack[top]
		if index < 0 || u64(index) >= u64(count) || seen[index] do return INVALID_RESULT
		seen[index] = true; base := int(index)*3
		value := nodes[base]; left := nodes[base+1]; right := nodes[base+2]
		if value < -1_000_000_000 || value > 1_000_000_000 || left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(count)) || (right >= 0 && u64(right) >= u64(count)) do return INVALID_RESULT
		if left >= 0 { stack[top] = left; top += 1 }
		if right >= 0 { stack[top] = right; top += 1 }
	}
	return if check_node(nodes,root) { 1 } else { 0 }
}
