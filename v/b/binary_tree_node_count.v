module binary_tree_node_count

const max_node_count = 900
@[export: 'binary_tree_node_count']
pub fn binary_tree_node_count(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count == 0 || node_count > max_node_count || root_index < 0 || u64(root_index) >= u64(node_count) {
		return i64(-9_000_000_000_000_000_000)
	}
	unsafe {
		mut queue := []int{len: max_node_count}
		mut seen := []bool{len: max_node_count}
		mut head := 0
		mut tail := 1
		mut count := 0
		root := int(root_index)
		queue[0] = root
		seen[root] = true
		for head < tail {
			node := queue[head]
			head++
			left := nodes[3 * node + 1]
			right := nodes[3 * node + 2]
			if left < -1 || right < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
				(right >= 0 && u64(right) >= u64(node_count)) {
				return i64(-9_000_000_000_000_000_000)
			}
			count++
			if left >= 0 {
				child := int(left)
				if seen[child] || tail >= int(node_count) { return i64(-9_000_000_000_000_000_000) }
				seen[child] = true
				queue[tail] = child
				tail++
			}
			if right >= 0 {
				child := int(right)
				if seen[child] || tail >= int(node_count) { return i64(-9_000_000_000_000_000_000) }
				seen[child] = true
				queue[tail] = child
				tail++
			}
		}
		return i64(count)
	}
}
