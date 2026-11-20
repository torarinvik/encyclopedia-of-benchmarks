module y_fast_trie_static_predecessor

const max_keys = 256
const max_queries = 256
const bucket_size = 16
const max_buckets = 16
const max_trie_nodes = 257
const max_input_values = 514
const max_parseable_values = 515

fn successor_bucket(children [514]int, min_rank [257]int, leaf_rank [257]int, query int, bucket_count int) int {
	if bucket_count == 0 { return -1 }
	mut node := 0
	mut candidate := -1
	for bit_position in 0 .. 16 {
		shift := 15 - bit_position
		branch := (query >> shift) & 1
		if branch == 0 {
			right_child := children[node * 2 + 1]
			if right_child >= 0 { candidate = min_rank[right_child] }
		}
		next_node := children[node * 2 + branch]
		if next_node < 0 { node = -1; break }
		node = next_node
	}
	if node >= 0 && leaf_rank[node] >= 0 { return leaf_rank[node] }
	if candidate >= 0 { return candidate }
	return bucket_count - 1
}

fn lower_bound(keys [256]int, start int, end int, query int) int {
	mut low := start
	mut high := end
	for low < high {
		middle := low + (high - low) / 2
		if keys[middle] < query { low = middle + 1 } else { high = middle }
	}
	return low
}

fn upper_bound(keys [256]int, start int, end int, query int) int {
	mut low := start
	mut high := end
	for low < high {
		middle := low + (high - low) / 2
		if keys[middle] <= query { low = middle + 1 } else { high = middle }
	}
	return low
}

@[export: 'y_fast_trie_static_predecessor']
pub fn y_fast_trie_static_predecessor(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable_values { return -1 }
		n_value, q_value := input[0], input[1]
		if n_value < 0 || n_value > max_keys || q_value < 0 || q_value > max_queries { return -1 }
		n, q := int(n_value), int(q_value)
		if length != usize(2 + n + q) || length > max_input_values { return -1 }
		mut keys := [256]int{}
		mut queries := [256]int{}
		for index in 0 .. n {
			value := input[2 + index]
			if value < 0 || value > 65535 { return -1 }
			keys[index] = int(value)
		}
		for index in 1 .. n {
			key := keys[index]
			mut position := index
			for position > 0 && key < keys[position - 1] {
				keys[position] = keys[position - 1]
				position--
			}
			keys[position] = key
		}
		for index in 1 .. n { if keys[index] == keys[index - 1] { return -1 } }
		for index in 0 .. q {
			value := input[2 + n + index]
			if value < 0 || value > 65535 { return -1 }
			queries[index] = int(value)
		}
		if n == 0 || q == 0 { return 0 }

		bucket_count := (n + bucket_size - 1) / bucket_size
		mut children := [514]int{}
		mut min_rank := [257]int{}
		mut leaf_rank := [257]int{}
		for node in 0 .. max_trie_nodes {
			children[node * 2] = -1
			children[node * 2 + 1] = -1
			min_rank[node] = -1
			leaf_rank[node] = -1
		}
		min_rank[0] = 0
		mut node_count := 1
		for bucket in 0 .. bucket_count {
			mut end := (bucket + 1) * bucket_size
			if end > n { end = n }
			separator := keys[end - 1]
			mut node := 0
			for bit_position in 0 .. 16 {
				shift := 15 - bit_position
				branch := (separator >> shift) & 1
				slot := node * 2 + branch
				mut child := children[slot]
				if child < 0 {
					child = node_count
					children[slot] = child
					children[child * 2] = -1
					children[child * 2 + 1] = -1
					min_rank[child] = bucket
					node_count++
				} else if min_rank[child] < 0 || bucket < min_rank[child] { min_rank[child] = bucket }
				node = child
			}
			leaf_rank[node] = bucket
		}

		mut checksum := i64(0)
		for index in 0 .. q {
			query := queries[index]
			bucket := successor_bucket(children, min_rank, leaf_rank, query, bucket_count)
			start := bucket * bucket_size
			mut end := start + bucket_size
			if end > n { end = n }
			lower := lower_bound(keys, start, end, query)
			upper := upper_bound(keys, start, end, query)
			mut predecessor := -1
			mut successor := -1
			if lower > start { predecessor = keys[lower - 1] } else if bucket > 0 { predecessor = keys[start - 1] }
			if upper < end { successor = keys[upper] } else if bucket + 1 < bucket_count { successor = keys[end] }
			checksum += i64(index + 1) * ((i64(predecessor) + 1) + 65537 * (i64(successor) + 1))
		}
		return checksum
	}
}
