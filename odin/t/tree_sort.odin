package tree_sort

import "core:c"

@(export)
tree_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > 1024 do return
	n := int(length)
	keys: [1024]i64
	left: [1024]int
	right: [1024]int
	stack: [1024]int
	root := n
	for index := 0; index < n; index += 1 {
		keys[index] = values[index]
		left[index] = n
		right[index] = n
		if root == n { root = index; continue }
		node := root
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
	current := root
	stack_size := 0
	output := 0
	for current != n || stack_size > 0 {
		for current != n { stack[stack_size] = current; stack_size += 1; current = left[current] }
		stack_size -= 1
		current = stack[stack_size]
		values[output] = keys[current]
		output += 1
		current = right[current]
	}
}
