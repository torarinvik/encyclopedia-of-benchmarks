package move_to_root_bst_access_trace

import "core:c"

@(export)
move_to_root_bst_access_trace :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 51 do return -1
	initial_count := values[0]
	if initial_count < 0 || initial_count > 16 do return -1
	query_count_index := 1 + int(initial_count)
	if length < c.size_t(query_count_index + 1) do return -1
	access_count := values[query_count_index]
	if access_count < 0 || access_count > 32 do return -1
	if length != c.size_t(query_count_index + 1 + int(access_count)) do return -1

	keys: [16]i64
	left: [16]int
	right: [16]int
	parent: [16]int
	for index: int = 0; index < 16; index += 1 {
		left[index] = -1
		right[index] = -1
		parent[index] = -1
	}
	for index: int = 0; index < int(initial_count); index += 1 {
		key := values[1 + index]
		if key < -100 || key > 100 do return -1
		for earlier: int = 0; earlier < index; earlier += 1 {
			if values[1 + earlier] == key do return -1
		}
		keys[index] = key
	}
	for query: int = 0; query < int(access_count); query += 1 {
		key := values[query_count_index + 1 + query]
		if key < -100 || key > 100 do return -1
	}

	root := -1
	for node: int = 0; node < int(initial_count); node += 1 {
		if root == -1 {
			root = node
			continue
		}
		current := root
		for {
			if keys[node] < keys[current] {
				if left[current] == -1 {
					left[current] = node
					parent[node] = current
					break
				}
				current = left[current]
			} else {
				if right[current] == -1 {
					right[current] = node
					parent[node] = current
					break
				}
				current = right[current]
			}
		}
	}

	result: i64 = 0
	for query_number: int = 1; query_number <= int(access_count); query_number += 1 {
		key := values[query_count_index + query_number]
		node := root
		comparisons: i64 = 0
		for node != -1 {
			comparisons += 1
			if key == keys[node] do break
			if key < keys[node] do node = left[node]
			else do node = right[node]
		}
		for node != -1 && parent[node] != -1 {
			old_parent := parent[node]
			grandparent := parent[old_parent]
			if left[old_parent] == node {
				middle := right[node]
				right[node] = old_parent
				left[old_parent] = middle
				if middle != -1 do parent[middle] = old_parent
			} else {
				middle := left[node]
				left[node] = old_parent
				right[old_parent] = middle
				if middle != -1 do parent[middle] = old_parent
			}
			parent[old_parent] = node
			parent[node] = grandparent
			if grandparent == -1 do root = node
			else if left[grandparent] == old_parent do left[grandparent] = node
			else do right[grandparent] = node
		}
		result += i64(query_number) * comparisons
	}
	return result
}
