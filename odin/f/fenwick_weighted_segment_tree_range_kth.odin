// Dynamic range k-th via a Fenwick tree of mutable weighted value trees.
package fenwick_weighted_segment_tree_range_kth

import "core:c"

MAX_N :: 12
MAX_Q :: 16
VALUE_COUNT :: 61
NODE_CAPACITY :: 1280

Pool :: struct {
	left: [NODE_CAPACITY + 1]int,
	right: [NODE_CAPACITY + 1]int,
	count: [NODE_CAPACITY + 1]int,
	roots: [MAX_N + 1]int,
	current: [MAX_N]int,
	used: int,
}

change :: proc(pool: ^Pool, root_arg, low, high, coordinate, delta: int) -> int {
	root := root_arg
	if root == 0 {
		pool.used += 1
		root = pool.used
	}
	pool.count[root] += delta
	if high - low > 1 {
		middle := (low + high) / 2
		if coordinate < middle {
			pool.left[root] = change(pool, pool.left[root], low, middle, coordinate, delta)
		} else {
			pool.right[root] = change(pool, pool.right[root], middle, high, coordinate, delta)
		}
	}
	return root
}

apply :: proc(pool: ^Pool, n, position, value, delta: int) {
	node := position + 1
	for node <= n {
		pool.roots[node] = change(pool, pool.roots[node], 0, VALUE_COUNT, value + 30, delta)
		node += node & -node
	}
}

@(export)
fenwick_weighted_segment_tree_range_kth :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 79 do return i64(-9223372036854775807) - 1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q do return i64(-9223372036854775807) - 1
	n, q := int(input[0]), int(input[1])
	if int(length) != 2 + n + 4 * q do return i64(-9223372036854775807) - 1

	pool: Pool
	for position := 0; position < n; position += 1 {
		value := input[2 + position]
		if value < -30 || value > 30 do return i64(-9223372036854775807) - 1
		pool.current[position] = int(value)
		apply(&pool, n, position, int(value), 1)
	}

	checksum := i64(0)
	query_number := 0
	cursor := 2 + n
	for _op := 0; _op < q; _op += 1 {
		opcode, first := input[cursor], input[cursor + 1]
		second, third := input[cursor + 2], input[cursor + 3]
		cursor += 4
		if opcode == 0 {
			if first < 0 || first >= i64(n) || second < -30 || second > 30 || third != 0 do return i64(-9223372036854775807) - 1
			position := int(first)
			apply(&pool, n, position, pool.current[position], -1)
			pool.current[position] = int(second)
			apply(&pool, n, position, pool.current[position], 1)
		} else if opcode == 1 {
			if first < 0 || first >= second || second > i64(n) || third < 1 || third > second - first do return i64(-9223372036854775807) - 1
			left_roots, right_roots: [MAX_N + 1]int
			left_size, right_size := 0, 0
			for node := int(first); node > 0; node -= node & -node {
				left_roots[left_size] = pool.roots[node]
				left_size += 1
			}
			for node := int(second); node > 0; node -= node & -node {
				right_roots[right_size] = pool.roots[node]
				right_size += 1
			}
			low, high, rank := 0, VALUE_COUNT, int(third)
			for high - low > 1 {
				middle := (low + high) / 2
				left_count := 0
				for i := 0; i < right_size; i += 1 do left_count += pool.count[pool.left[right_roots[i]]]
				for i := 0; i < left_size; i += 1 do left_count -= pool.count[pool.left[left_roots[i]]]
				if rank <= left_count {
					for i := 0; i < right_size; i += 1 do right_roots[i] = pool.left[right_roots[i]]
					for i := 0; i < left_size; i += 1 do left_roots[i] = pool.left[left_roots[i]]
					high = middle
				} else {
					rank -= left_count
					for i := 0; i < right_size; i += 1 do right_roots[i] = pool.right[right_roots[i]]
					for i := 0; i < left_size; i += 1 do left_roots[i] = pool.right[left_roots[i]]
					low = middle
				}
			}
			query_number += 1
			checksum += i64(query_number) * i64(low - 30)
		} else do return i64(-9223372036854775807) - 1
	}
	return checksum
}
