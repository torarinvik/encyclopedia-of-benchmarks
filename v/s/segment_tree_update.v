module segment_tree_update

const max_n = 64
const max_operations = 64
const max_input_length = 259
const max_tree_length = 128
const value_min = i64(-1_000_000)
const value_max = i64(1_000_000)
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)
const mask_63 = u64(0x7fffffffffffffff)

fn query_sum(tree &i32, node int, segment_left int, segment_right int, query_left int, query_right int) i32 {
	if query_left <= segment_left && segment_right <= query_right { return unsafe { tree[node] } }
	if query_right < segment_left || segment_right < query_left { return 0 }
	middle := segment_left + (segment_right - segment_left) / 2
	return query_sum(tree, node * 2, segment_left, middle, query_left, query_right) +
		query_sum(tree, node * 2 + 1, middle + 1, segment_right, query_left, query_right)
}

fn hash_i64_word(hash_value u64, word i64) u64 {
	mut hash := hash_value
	mut bits := u64(word)
	for _ in 0 .. 8 {
		hash = (hash ^ (bits & 255)) * fnv_prime
		bits >>= 8
	}
	return hash
}

@[export: 'segment_tree_update_benchmark']
pub fn segment_tree_update_benchmark(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_length { return -1 }
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if length < usize(n + 2) { return -1 }
		if input[n + 1] < 1 || input[n + 1] > max_operations { return -1 }
		operation_count := int(input[n + 1])
		if length != usize(n + 2 + 3 * operation_count) { return -1 }

		for index := 0; index < n; index++ {
			if input[index + 1] < value_min || input[index + 1] > value_max { return -1 }
		}
		operations_start := n + 2
		mut query_count := 0
		for operation := 0; operation < operation_count; operation++ {
			offset := operations_start + 3 * operation
			kind, first, second := input[offset], input[offset + 1], input[offset + 2]
			if kind == 0 {
				if first < 0 || first > second || second >= i64(n) { return -1 }
				query_count++
			} else if kind == 1 {
				if first < 0 || first >= i64(n) || second < value_min || second > value_max { return -1 }
			} else {
				return -1
			}
		}
		if query_count == 0 { return -1 }

		mut power := 1
		for power < n { power *= 2 }
		mut tree := [max_tree_length]i32{}
		for index := 0; index < n; index++ { tree[power + index] = i32(input[index + 1]) }
		for node := power - 1; node > 0; node-- { tree[node] = tree[node * 2] + tree[node * 2 + 1] }

		mut hash := hash_i64_word(fnv_offset, i64(query_count))
		for operation := 0; operation < operation_count; operation++ {
			offset := operations_start + 3 * operation
			kind, first, second := input[offset], input[offset + 1], input[offset + 2]
			if kind == 0 {
				sum := query_sum(&tree[0], 1, 1, power, int(first) + 1, int(second) + 1)
				hash = hash_i64_word(hash, i64(sum))
			} else {
				mut node := power + int(first)
				tree[node] = i32(second)
				for node > 1 {
					node /= 2
					tree[node] = tree[node * 2] + tree[node * 2 + 1]
				}
			}
		}
		return i64(hash & mask_63)
	}
}
