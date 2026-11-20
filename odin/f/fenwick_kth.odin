// Fenwick frequency selection by binary lifting over prefix blocks.
package fenwick_kth

import "core:c"

@(export)
fenwick_kth :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 163 do return -1
	if input[0] < 1 || input[0] > 64 || input[1] < 0 || input[1] > 32 do return -1
	n := int(input[0])
	q := int(input[1])
	if int(length) != 2 + n + 3 * q do return -1

	frequency: [64]i64 = {}
	tree: [65]i64 = {}
	total: i64 = 0
	for i := 0; i < n; i += 1 {
		value := input[2 + i]
		if value < 0 || value > 1_000_000 do return -1
		frequency[i] = value
		total += value
		index := i + 1
		tree[index] += value
		parent := index + (index & -index)
		if parent <= n do tree[parent] += tree[index]
	}

	result: i64 = 0
	query_number := 0
	cursor := 2 + n
	for _operation := 0; _operation < q; _operation += 1 {
		opcode := input[cursor]
		first := input[cursor + 1]
		second := input[cursor + 2]
		cursor += 3
		if opcode == 0 {
			if first < 0 || first >= i64(n) || second < -1_000_000 || second > 1_000_000 do return -1
			position := int(first)
			updated := frequency[position] + second
			if updated < 0 || updated > 1_000_000 do return -1
			frequency[position] = updated
			total += second
			index := position + 1
			for index <= n {
				tree[index] += second
				index += index & -index
			}
		} else if opcode == 1 {
			if second != 0 do return -1
			answer: i64 = -1
			if first > 0 && first <= total {
				index := 0
				step := 1
				for step <= n / 2 { step *= 2 }
				rank := first
				for step > 0 {
					candidate := index + step
					if candidate <= n && tree[candidate] < rank {
						index = candidate
						rank -= tree[candidate]
					}
					step /= 2
				}
				answer = i64(index)
			}
			result += i64(query_number + 1) * (answer + 1)
			query_number += 1
		} else {
			return -1
		}
	}
	return result
}
