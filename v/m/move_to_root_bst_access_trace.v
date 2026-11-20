module move_to_root_bst_access_trace

@[export: 'move_to_root_bst_access_trace']
pub fn move_to_root_bst_access_trace(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > 51 { return -1 }
		initial_count := values[0]
		if initial_count < 0 || initial_count > 16 { return -1 }
		query_count_index := 1 + int(initial_count)
		if length < usize(query_count_index + 1) { return -1 }
		access_count := values[query_count_index]
		if access_count < 0 || access_count > 32 { return -1 }
		if length != usize(query_count_index + 1 + int(access_count)) { return -1 }

		mut keys := [16]i64{}
		mut left := [16]int{}
		mut right := [16]int{}
		mut parent := [16]int{}
		for index in 0 .. 16 {
			left[index] = -1
			right[index] = -1
			parent[index] = -1
		}
		for index in 0 .. int(initial_count) {
			key := values[1 + index]
			if key < -100 || key > 100 { return -1 }
			for earlier in 0 .. index {
				if values[1 + earlier] == key { return -1 }
			}
			keys[index] = key
		}
		for query in 0 .. int(access_count) {
			key := values[query_count_index + 1 + query]
			if key < -100 || key > 100 { return -1 }
		}

		mut root := -1
		for node in 0 .. int(initial_count) {
			if root == -1 {
				root = node
				continue
			}
			mut current := root
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

		mut result := i64(0)
		for query_number in 1 .. int(access_count) + 1 {
			key := values[query_count_index + query_number]
			mut node := root
			mut comparisons := i64(0)
			for node != -1 {
				comparisons++
				if key == keys[node] { break }
				if key < keys[node] { node = left[node] } else { node = right[node] }
			}
			for node != -1 && parent[node] != -1 {
				old_parent := parent[node]
				grandparent := parent[old_parent]
				if left[old_parent] == node {
					middle := right[node]
					right[node] = old_parent
					left[old_parent] = middle
					if middle != -1 { parent[middle] = old_parent }
				} else {
					middle := left[node]
					left[node] = old_parent
					right[old_parent] = middle
					if middle != -1 { parent[middle] = old_parent }
				}
				parent[old_parent] = node
				parent[node] = grandparent
				if grandparent == -1 { root = node }
				else if left[grandparent] == old_parent { left[grandparent] = node }
				else { right[grandparent] = node }
			}
			result += i64(query_number) * comparisons
		}
		return result
	}
}
