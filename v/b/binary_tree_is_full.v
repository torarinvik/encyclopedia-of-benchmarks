module binary_tree_is_full

const max_n = 1024

@[export: 'binary_tree_is_full']
pub fn binary_tree_is_full(input &i64, length usize) i64 {
	if isnil(input) || length < 2 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > i64(max_n) { return -1 }
		n := int(input[0])
		root_value := input[1]
		if root_value < 0 || root_value >= i64(n) || length != usize(2 + 2 * n) { return -1 }
		mut left := []int{len: max_n}
		mut right := []int{len: max_n}
		mut parents := []int{len: max_n}
		mut stack := []int{len: max_n}
		mut seen := []bool{len: max_n}
		mut full := true
		for i in 0 .. n {
			l := input[2 + 2 * i]
			r := input[3 + 2 * i]
			if l < -1 || l >= i64(n) || r < -1 || r >= i64(n) || l == i64(i) || r == i64(i) { return -1 }
			left[i] = int(l)
			right[i] = int(r)
			if l >= 0 { parents[int(l)]++ }
			if r >= 0 { parents[int(r)]++ }
			if (l < 0) != (r < 0) { full = false }
		}
		root := int(root_value)
		if parents[root] != 0 { return -1 }
		for i in 0 .. n { if i != root && parents[i] != 1 { return -1 } }
		mut top := 1
		mut visited := 0
		stack[0] = root
		for top > 0 {
			top--
			node := stack[top]
			if seen[node] { return -1 }
			seen[node] = true
			visited++
			if left[node] >= 0 { stack[top] = left[node]; top++ }
			if right[node] >= 0 { stack[top] = right[node]; top++ }
		}
		if visited != n { return -1 }
		return if full { i64(1) } else { i64(0) }
	}
}
