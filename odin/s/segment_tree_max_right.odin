// Point updates and sum-monoid max_right boundary searches.
package segment_tree_max_right

import "core:c"

@(export)
segment_tree_max_right :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 55 do return -1
	if input[0] < 0 || input[0] > 16 || input[1] < 0 || input[1] > 12 do return -1
	n := int(input[0])
	operations := int(input[1])
	if int(length) != 2 + n + 3 * operations do return -1

	tree: [64]i64 = {}
	size := 1
	for size < n { size *= 2 }
	for i := 0; i < n; i += 1 {
		value := input[2 + i]
		if value < 0 || value > 1000 do return -1
		tree[size + i] = value
	}
	node := size
	for node > 1 {
		node -= 1
		tree[node] = tree[2 * node] + tree[2 * node + 1]
	}

	query_index := 0
	result: i64 = 0
	cursor := 2 + n
	for operation := 0; operation < operations; operation += 1 {
		opcode := input[cursor]
		first := input[cursor + 1]
		second := input[cursor + 2]
		cursor += 3
		if opcode == 0 {
			if first < 0 || first >= i64(n) || second < 0 || second > 1000 do return -1
			node = size + int(first)
			tree[node] = second
			for node > 1 {
				node /= 2
				tree[node] = tree[2 * node] + tree[2 * node + 1]
			}
		} else if opcode == 1 {
			if first < 0 || first > i64(n) || second < 0 || second > 16000 do return -1
			left := int(first)
			boundary := n
			if left < n {
				position := left + size
				accumulated: i64 = 0
				done := false
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
