module binary_tree_traversal

const max_nodes = 64
const max_input_length = 3 + 3 * max_nodes

fn walk(order i64, values []i64, left []i64, right []i64, node int, mut output []i64, mut used []int) {
	if order == 0 { output[used[0]] = values[node]; used[0]++ }
	if left[node] >= 0 { walk(order, values, left, right, int(left[node]), mut output, mut used) }
	if order == 1 { output[used[0]] = values[node]; used[0]++ }
	if right[node] >= 0 { walk(order, values, left, right, int(right[node]), mut output, mut used) }
	if order == 2 { output[used[0]] = values[node]; used[0]++ }
}

fn breadth_first(order i64, values []i64, left []i64, right []i64, root int, mut output []i64, mut used []int) {
	mut queue := []int{len: max_nodes}
	mut head := 0
	mut tail := 1
	queue[0] = root
	for head < tail {
		node := queue[head]
		head++
		output[used[0]] = values[node]
		used[0]++
		first := if order == 3 { left[node] } else { right[node] }
		second := if order == 3 { right[node] } else { left[node] }
		if first >= 0 { queue[tail] = int(first); tail++ }
		if second >= 0 { queue[tail] = int(second); tail++ }
	}
}

fn breadth_first_zigzag(values []i64, left []i64, right []i64, root int, mut output []i64, mut used []int) {
	mut queue := []int{len: max_nodes}
	mut head := 0
	mut tail := 1
	mut level := 0
	queue[0] = root
	for head < tail {
		level_end := tail
		level_start := used[0]
		for head < level_end {
			node := queue[head]
			head++
			output[used[0]] = values[node]
			used[0]++
			if left[node] >= 0 { queue[tail] = int(left[node]); tail++ }
			if right[node] >= 0 { queue[tail] = int(right[node]); tail++ }
		}
		if level % 2 == 1 {
			mut lo := level_start
			mut hi := used[0] - 1
			for lo < hi {
				temp := output[lo]
				output[lo] = output[hi]
				output[hi] = temp
				lo++
				hi--
			}
		}
		level++
	}
}

fn mark_reachable(left []i64, right []i64, root int, mut seen []bool) int {
	mut stack := []int{len: max_nodes}
	mut top := 1
	mut count := 0
	stack[0] = root
	for top > 0 {
		top--
		node := stack[top]
		if seen[node] { continue }
		seen[node] = true
		count++
		if right[node] >= 0 { stack[top] = int(right[node]); top++ }
		if left[node] >= 0 { stack[top] = int(left[node]); top++ }
	}
	return count
}

@[export: 'binary_tree_traversal']
pub fn binary_tree_traversal(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_length { return -1 }
		order := input[0]; count_value := input[1]; root_value := input[2]
		if order < 0 || order > 6 || count_value < 0 || count_value > max_nodes { return -1 }
		n := int(count_value)
		if length != usize(3 + 3 * n) || (n == 0 && root_value != -1) || (n > 0 && (root_value < 0 || root_value >= count_value)) { return -1 }
		mut values := []i64{len: max_nodes}
		mut left := []i64{len: max_nodes, init: -1}
		mut right := []i64{len: max_nodes, init: -1}
		mut parents := []u8{len: max_nodes}
		for i in 0 .. n {
			values[i] = input[3 + 3 * i]
			left[i] = input[4 + 3 * i]
			right[i] = input[5 + 3 * i]
			if left[i] < -1 || left[i] >= count_value || right[i] < -1 || right[i] >= count_value || left[i] == i64(i) || right[i] == i64(i) { return -1 }
			if left[i] >= 0 { parents[int(left[i])]++; if parents[int(left[i])] > 1 { return -1 } }
			if right[i] >= 0 { parents[int(right[i])]++; if parents[int(right[i])] > 1 { return -1 } }
		}
		mut result := []i64{len: max_nodes}
		mut used := []int{len: 1}
		if n > 0 {
			root := int(root_value)
			for i in 0 .. n { expected := u8(1); if i == root { expected = 0 }; if parents[i] != expected { return -1 } }
			mut seen := []bool{len: max_nodes}
			if mark_reachable(left, right, root, mut seen) != n { return -1 }
			if order <= 2 { walk(order, values, left, right, root, mut result, mut used) }
			else if order == 5 { walk(1, values, right, left, root, mut result, mut used) }
			else if order == 6 { breadth_first_zigzag(values, left, right, root, mut result, mut used) }
			else { breadth_first(order, values, left, right, root, mut result, mut used) }
		}
		if output == nil || capacity < usize(used[0] * 8) { return -2 }
		for i in 0 .. used[0] {
			bits := u64(result[i])
			for byte in 0 .. 8 { output[i * 8 + byte] = u8((bits >> u64(8 * byte)) & 255) }
		}
		return i64(used[0] * 8)
	}
}
