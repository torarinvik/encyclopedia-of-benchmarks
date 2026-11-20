module divide_combine_tree_incremental

const max_n = 16
const max_nodes = 31
const tree_size = 68

fn dct_add(node int, left int, right int, ql int, qr int, delta int, mut minimum []int, mut lazy []int) {
	if ql <= left && right <= qr {
		minimum[node] += delta
		lazy[node] += delta
		return
	}
	middle := (left + right) / 2
	if lazy[node] != 0 {
		tag := lazy[node]
		minimum[node * 2] += tag
		minimum[node * 2 + 1] += tag
		lazy[node * 2] += tag
		lazy[node * 2 + 1] += tag
		lazy[node] = 0
	}
	if ql <= middle && qr >= left {
		dct_add(node * 2, left, middle, ql, qr, delta, mut minimum, mut lazy)
	}
	if qr > middle && ql <= right {
		dct_add(node * 2 + 1, middle + 1, right, ql, qr, delta, mut minimum, mut lazy)
	}
	minimum[node] = if minimum[node * 2] < minimum[node * 2 + 1] { minimum[node * 2] } else { minimum[node * 2 + 1] }
}

fn dct_first_zero(node int, left int, right int, minimum []int) int {
	if left == right { return left }
	middle := (left + right) / 2
	if minimum[node * 2] == 0 { return dct_first_zero(node * 2, left, middle, minimum) }
	return dct_first_zero(node * 2 + 1, middle + 1, right, minimum)
}

fn dct_connected(left int, right int, logs []int, range_min []int, range_max []int) bool {
	level := logs[right - left + 1]
	other := right + 1 - (1 << level)
	low := range_min[level * max_n + left]
	if range_min[level * max_n + other] < low { low = range_min[level * max_n + other] }
	high := range_max[level * max_n + left]
	if range_max[level * max_n + other] > high { high = range_max[level * max_n + other] }
	return high - low == right - left
}

@[export: 'divide_combine_tree_incremental']
pub fn divide_combine_tree_incremental(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_n + 2 { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n || length != usize(n_value + 1) { return -1 }
	n := int(n_value)
	mut permutation := [max_n]int{}
	mut seen := [max_n]bool{}
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < 0 || value >= i64(n) || seen[int(value)] { return -1 }
		permutation[i] = int(value)
		seen[int(value)] = true
	}
	mut logs := [max_n + 1]int{}
	for i in 2 .. n + 1 { logs[i] = logs[i / 2] + 1 }
	levels := logs[n] + 1
	mut range_min := [max_n * max_n]int{}
	mut range_max := [max_n * max_n]int{}
	for i in 0 .. n {
		range_min[i] = permutation[i]
		range_max[i] = permutation[i]
	}
	for level in 1 .. levels {
		half := 1 << (level - 1)
		width := 2 * half
		mut start := 0
		for start + width <= n {
			a := range_min[(level - 1) * max_n + start]
			b := range_min[(level - 1) * max_n + start + half]
			range_min[level * max_n + start] = if a < b { a } else { b }
			a = range_max[(level - 1) * max_n + start]
			b = range_max[(level - 1) * max_n + start + half]
			range_max[level * max_n + start] = if a > b { a } else { b }
			start++
		}
	}
	mut segment_min := [tree_size]int{}
	mut lazy := [tree_size]int{}
	mut node_left := [max_nodes]int{}
	mut node_right := [max_nodes]int{}
	mut node_combine := [max_nodes]bool{}
	mut node_last := [max_nodes]int{}
	mut node_stack := [max_n]int{}
	mut min_stack := [max_n]int{}
	mut max_stack := [max_n]int{}
	mut node_top := 0
	mut min_top := 0
	mut max_top := 0
	mut node_count := 0
	for ending in 0 .. n {
		value := permutation[ending]
		for min_top > 0 && permutation[min_stack[min_top - 1]] >= value {
			min_top--
			position := min_stack[min_top]
			start := if min_top > 0 { min_stack[min_top - 1] + 1 } else { 0 }
			dct_add(1, 0, n - 1, start, position, permutation[position], mut segment_min[..], mut lazy[..])
		}
		for max_top > 0 && permutation[max_stack[max_top - 1]] <= value {
			max_top--
			position := max_stack[max_top]
			start := if max_top > 0 { max_stack[max_top - 1] + 1 } else { 0 }
			dct_add(1, 0, n - 1, start, position, -permutation[position], mut segment_min[..], mut lazy[..])
		}
		mut start := if min_top > 0 { min_stack[min_top - 1] + 1 } else { 0 }
		dct_add(1, 0, n - 1, start, ending, -value, mut segment_min[..], mut lazy[..])
		min_stack[min_top] = ending
		min_top++
		start = if max_top > 0 { max_stack[max_top - 1] + 1 } else { 0 }
		dct_add(1, 0, n - 1, start, ending, value, mut segment_min[..], mut lazy[..])
		max_stack[max_top] = ending
		max_top++
		leftmost := dct_first_zero(1, 0, n - 1, segment_min[..])
		mut current := node_count
		node_count++
		node_left[current] = ending
		node_right[current] = ending
		for node_top > 0 && node_left[node_stack[node_top - 1]] >= leftmost {
			top := node_stack[node_top - 1]
			if node_combine[top] && dct_connected(node_last[top], ending, logs[..], range_min[..], range_max[..]) {
				node_right[top] = ending
				node_last[top] = node_left[current]
				node_top--
				current = node_stack[node_top]
			} else if dct_connected(node_left[top], ending, logs[..], range_min[..], range_max[..]) {
				merged := node_count
				node_count++
				node_left[merged] = node_left[top]
				node_right[merged] = ending
				node_combine[merged] = true
				node_last[merged] = node_left[current]
				node_top--
				current = merged
			} else {
				merged := node_count
				node_count++
				node_left[merged] = -1
				node_right[merged] = ending
				node_top--
				for node_top > 0 && !dct_connected(node_left[node_stack[node_top - 1]], ending, logs[..], range_min[..], range_max[..]) {
					node_top--
				}
				if node_top == 0 { return -1 }
				node_top--
				base := node_stack[node_top]
				node_left[merged] = node_left[base]
				current = merged
			}
		}
		node_stack[node_top] = current
		node_top++
		dct_add(1, 0, n - 1, 0, ending, -1, mut segment_min[..], mut lazy[..])
	}
	for i in 1 .. node_count {
		left := node_left[i]
		right := node_right[i]
		mut j := i
		for j > 0 && (node_left[j - 1] > left || (node_left[j - 1] == left && node_right[j - 1] > right)) {
			node_left[j] = node_left[j - 1]
			node_right[j] = node_right[j - 1]
			j--
		}
		node_left[j] = left
		node_right[j] = right
	}
	mut checksum := i64(0)
	for i in 0 .. node_count {
		checksum += i64(i + 1) * (i64(node_left[i] + 1) * i64(n + 1) + i64(node_right[i] + 1))
	}
	return checksum
}
