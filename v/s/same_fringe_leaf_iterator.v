module same_fringe_leaf_iterator

const max_tree_nodes = i64(15)
const max_total_nodes = 30
const max_parseable_length = 93

fn valid_tree(input &i64, offset int, node_count int) bool {
	unsafe {
		mut visited := [15]bool{}
		mut parents := [15]int{}
		mut stack := [15]int{}
		mut top := 1
		mut reached := 0
		for top > 0 {
			top--
			node := stack[top]
			if node < 0 || node >= node_count || visited[node] { return false }
			visited[node] = true
			reached++
			base := offset + 3 * node
			left := input[base + 1]
			right := input[base + 2]
			if left == -1 && right == -1 { continue }
			if left < 0 || right < 0 || left >= i64(node_count) || right >= i64(node_count) ||
				left == right || left == 0 || right == 0 { return false }
			parents[int(left)]++
			parents[int(right)]++
			if parents[int(left)] != 1 || parents[int(right)] != 1 { return false }
			stack[top] = int(right)
			top++
			stack[top] = int(left)
			top++
		}
		if reached != node_count || parents[0] != 0 { return false }
		for node := 1; node < node_count; node++ {
			if parents[node] != 1 { return false }
		}
		return true
	}
}

@[export: 'same_fringe_leaf_iterator']
pub fn same_fringe_leaf_iterator(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_parseable_length) { return -1 }
		n_a_word := input[0]
		n_b_word := input[1]
		if n_a_word < 1 || n_a_word > max_tree_nodes || n_b_word < 1 || n_b_word > max_tree_nodes { return -1 }
		n_a := int(n_a_word)
		n_b := int(n_b_word)
		if n_a + n_b > max_total_nodes || length != usize(2 + 3 * (n_a + n_b)) { return -1 }
		offset_a := 2
		offset_b := 2 + 3 * n_a
		if !valid_tree(input, offset_a, n_a) || !valid_tree(input, offset_b, n_b) { return -1 }

		mut stack_a := [15]int{}
		mut stack_b := [15]int{}
		mut top_a := 1
		mut top_b := 1
		for {
			mut have_a := false
			mut have_b := false
			mut leaf_a := i64(0)
			mut leaf_b := i64(0)
			for top_a > 0 && !have_a {
				top_a--
				node := stack_a[top_a]
				base := offset_a + 3 * node
				left := input[base + 1]
				right := input[base + 2]
				if left == -1 {
					leaf_a = input[base]
					have_a = true
				} else {
					stack_a[top_a] = int(right)
					top_a++
					stack_a[top_a] = int(left)
					top_a++
				}
			}
			for top_b > 0 && !have_b {
				top_b--
				node := stack_b[top_b]
				base := offset_b + 3 * node
				left := input[base + 1]
				right := input[base + 2]
				if left == -1 {
					leaf_b = input[base]
					have_b = true
				} else {
					stack_b[top_b] = int(right)
					top_b++
					stack_b[top_b] = int(left)
					top_b++
				}
			}
			if !have_a || !have_b {
				if have_a == have_b { return 1 }
				return 0
			}
			if leaf_a != leaf_b { return 0 }
		}
		return -1
	}
}
