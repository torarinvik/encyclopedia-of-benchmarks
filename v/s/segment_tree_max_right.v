// Point updates and sum-monoid max_right boundary searches.
module segment_tree_max_right

@[export: 'segment_tree_max_right']
pub fn segment_tree_max_right(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 55 { return -1 }
		if input[0] < 0 || input[0] > 16 || input[1] < 0 || input[1] > 12 { return -1 }
		n := int(input[0])
		operations := int(input[1])
		if int(length) != 2 + n + 3 * operations { return -1 }

		mut tree := [64]i64{}
		mut size := 1
		for size < n { size *= 2 }
		for i in 0 .. n {
			value := input[2 + i]
			if value < 0 || value > 1000 { return -1 }
			tree[size + i] = value
		}
		mut node := size
		for node > 1 {
			node -= 1
			tree[node] = tree[2 * node] + tree[2 * node + 1]
		}

		mut query_index := 0
		mut result := i64(0)
		mut cursor := 2 + n
		for _ in 0 .. operations {
			opcode := input[cursor]
			first := input[cursor + 1]
			second := input[cursor + 2]
			cursor += 3
			if opcode == 0 {
				if first < 0 || first >= i64(n) || second < 0 || second > 1000 { return -1 }
			node = size + int(first)
				tree[node] = second
				for node > 1 {
					node /= 2
					tree[node] = tree[2 * node] + tree[2 * node + 1]
				}
			} else if opcode == 1 {
				if first < 0 || first > i64(n) || second < 0 || second > 16000 { return -1 }
				left := int(first)
				mut boundary := n
				if left < n {
					mut position := left + size
					mut accumulated := i64(0)
					mut done := false
					for !done {
						for (position & 1) == 0 { position /= 2 }
						if accumulated + tree[position] > second {
							for position < size {
								position *= 2
								if accumulated + tree[position] <= second {
									accumulated += tree[position]
									position += 1
								}
							}
							boundary = min(position - size, n)
							done = true
						} else {
							accumulated += tree[position]
							position += 1
							if (position & (position - 1)) == 0 { done = true }
						}
					}
				}
				result |= i64(boundary) << u32(5 * query_index)
				query_index += 1
			} else {
				return -1
			}
		}
		return result
	}
}
