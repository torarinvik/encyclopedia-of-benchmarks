module tree_sort

const max_values = 1024

@[export: 'tree_sort']
pub fn tree_sort(mut values &i64, length usize) {
	if length > max_values { return }
	n := int(length)
	mut keys := [max_values]i64{}
	mut left := [max_values]int{}
	mut right := [max_values]int{}
	mut stack := [max_values]int{}
	mut root := n
	for index in 0 .. n {
		unsafe { keys[index] = values[index] }
		left[index] = n
		right[index] = n
		if root == n { root = index; continue }
		mut node := root
		for {
			if keys[index] < keys[node] {
				if left[node] == n { left[node] = index; break }
				node = left[node]
			} else {
				if right[node] == n { right[node] = index; break }
				node = right[node]
			}
		}
	}
	mut current := root
	mut stack_size := 0
	mut output := 0
	for current != n || stack_size > 0 {
		for current != n { stack[stack_size] = current; stack_size++; current = left[current] }
		stack_size--
		current = stack[stack_size]
		unsafe { values[output] = keys[current] }
		output++
		current = right[current]
	}
}
