module swap_sort

const max_values = 256

fn position_less(keys &i64, order &int, left int, right int) bool {
	a := unsafe { order[left] }
	b := unsafe { order[right] }
	return unsafe { keys[a] < keys[b] || (keys[a] == keys[b] && a < b) }
}

fn sift_down(keys &i64, mut order &int, heap_length int, start_root int) {
	mut root := start_root
	for root < heap_length / 2 {
		mut child := root * 2 + 1
		if child + 1 < heap_length && position_less(keys, order, child, child + 1) { child++ }
		if !position_less(keys, order, root, child) { break }
		unsafe { temporary := order[root]; order[root] = order[child]; order[child] = temporary }
		root = child
	}
}

@[export: 'swap_sort']
pub fn swap_sort(values &i64, length usize) i64 {
	if length > max_values { return -1 }
	n := int(length)
	mut keys := [max_values]i64{}
	mut order := [max_values]int{}
	mut visited := [max_values]bool{}
	for index in 0 .. n {
		unsafe { keys[index] = values[index] }
		order[index] = index
	}
	mut start := n / 2
	for start > 0 { start--; sift_down(&keys[0], mut order[0], n, start) }
	mut finish := n
	for finish > 1 {
		finish--
		temporary := order[0]; order[0] = order[finish]; order[finish] = temporary
		sift_down(&keys[0], mut order[0], finish, 0)
	}
	for index in 1 .. n {
		if keys[order[index - 1]] == keys[order[index]] { return -1 }
	}
	mut swaps := 0
	for first in 0 .. n {
		if visited[first] { continue }
		mut node := first
		mut cycle_length := 0
		for !visited[node] { visited[node] = true; node = order[node]; cycle_length++ }
		if cycle_length > 0 { swaps += cycle_length - 1 }
	}
	return i64(swaps)
}
