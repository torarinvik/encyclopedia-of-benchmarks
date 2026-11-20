// Dynamic range k-th via a Fenwick tree of mutable weighted value trees.
module fenwick_weighted_segment_tree_range_kth

const max_n = 12
const max_q = 16
const value_count = 61
const node_capacity = 1280

struct Pool {
	mut:
	left [1281]int
	right [1281]int
	count [1281]int
	roots [13]int
	current [12]int
	used int
}

fn fwk_change(mut pool Pool, root_arg int, low int, high int, coordinate int, delta int) int {
	mut root := root_arg
	if root == 0 {
		pool.used++
		root = pool.used
	}
	pool.count[root] += delta
	if high - low > 1 {
		middle := (low + high) / 2
		if coordinate < middle {
			pool.left[root] = fwk_change(mut pool, pool.left[root], low, middle, coordinate, delta)
		} else {
			pool.right[root] = fwk_change(mut pool, pool.right[root], middle, high, coordinate, delta)
		}
	}
	return root
}

fn fwk_apply(mut pool Pool, n int, position int, value int, delta int) {
	mut node := position + 1
	for node <= n {
		pool.roots[node] = fwk_change(mut pool, pool.roots[node], 0, value_count, value + 30, delta)
		node += node & -node
	}
}

@[export: 'fenwick_weighted_segment_tree_range_kth']
pub fn fenwick_weighted_segment_tree_range_kth(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 79 { return i64(-9223372036854775807) - 1 }
		n_value, q_value := input[0], input[1]
		if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_q { return i64(-9223372036854775807) - 1 }
		n, q := int(n_value), int(q_value)
		if int(length) != 2 + n + 4 * q { return i64(-9223372036854775807) - 1 }

		mut pool := Pool{}
		for position in 0 .. n {
			value := input[2 + position]
			if value < -30 || value > 30 { return i64(-9223372036854775807) - 1 }
			pool.current[position] = int(value)
			fwk_apply(mut pool, n, position, int(value), 1)
		}

		mut checksum := i64(0)
		mut query_number := 0
		mut cursor := 2 + n
		for _ in 0 .. q {
			opcode, first := input[cursor], input[cursor + 1]
			second, third := input[cursor + 2], input[cursor + 3]
			cursor += 4
			if opcode == 0 {
				if first < 0 || first >= i64(n) || second < -30 || second > 30 || third != 0 { return i64(-9223372036854775807) - 1 }
				position := int(first)
				fwk_apply(mut pool, n, position, pool.current[position], -1)
				pool.current[position] = int(second)
				fwk_apply(mut pool, n, position, pool.current[position], 1)
			} else if opcode == 1 {
				if first < 0 || first >= second || second > i64(n) || third < 1 || third > second - first { return i64(-9223372036854775807) - 1 }
				mut left_roots := [13]int{}
				mut right_roots := [13]int{}
				mut left_size := 0
				mut right_size := 0
				mut node := int(first)
				for node > 0 {
					left_roots[left_size] = pool.roots[node]
					left_size++
					node -= node & -node
				}
				node = int(second)
				for node > 0 {
					right_roots[right_size] = pool.roots[node]
					right_size++
					node -= node & -node
				}
				mut low := 0
				mut high := value_count
				mut rank := int(third)
				for high - low > 1 {
					middle := (low + high) / 2
					mut left_count := 0
					for i in 0 .. right_size { left_count += pool.count[pool.left[right_roots[i]]] }
					for i in 0 .. left_size { left_count -= pool.count[pool.left[left_roots[i]]] }
					if rank <= left_count {
						for i in 0 .. right_size { right_roots[i] = pool.left[right_roots[i]] }
						for i in 0 .. left_size { left_roots[i] = pool.left[left_roots[i]] }
						high = middle
					} else {
						rank -= left_count
						for i in 0 .. right_size { right_roots[i] = pool.right[right_roots[i]] }
						for i in 0 .. left_size { left_roots[i] = pool.right[left_roots[i]] }
						low = middle
					}
				}
				query_number++
				checksum += i64(query_number) * i64(low - 30)
			} else { return i64(-9223372036854775807) - 1 }
		}
		return checksum
	}
}
