module x_fast_trie_static_predecessor

const max_keys = 24
const max_queries = 24
const universe_bits = 16
const levels = 17
const max_parseable = 51

fn prefix_of(key i64, depth int) i64 {
	if depth == 0 { return 0 }
	return key >> (universe_bits - depth)
}

fn find_prefix(prefixes [levels * max_keys]i64, counts [levels]int, depth int, wanted i64) int {
	mut low := 0
	mut high := counts[depth]
	row := depth * max_keys
	for low < high {
		middle := low + (high - low) / 2
		if prefixes[row + middle] < wanted { low = middle + 1 } else { high = middle }
	}
	if low < counts[depth] && prefixes[row + low] == wanted { return low }
	return -1
}

fn predecessor(prefixes [levels * max_keys]i64, maxima [levels * max_keys]i64,
		counts [levels]int, query i64) i64 {
	mut low := 0
	mut high := levels
	for high - low > 1 {
		middle := low + (high - low) / 2
		if find_prefix(prefixes, counts, middle, prefix_of(query, middle)) >= 0 { low = middle } else { high = middle }
	}
	if low == universe_bits { return query }
	mut depth := low + 1
	for depth > 0 {
		query_prefix := query >> (universe_bits - depth)
		if query_prefix & 1 != 0 {
			position := find_prefix(prefixes, counts, depth, query_prefix - 1)
			if position >= 0 { return maxima[depth * max_keys + position] }
		}
		depth--
	}
	return -1
}

@[export: 'x_fast_trie_static_predecessor']
pub fn x_fast_trie_static_predecessor(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable { return -1 }
		if input[0] < 0 || input[0] > max_keys || input[1] < 0 || input[1] > max_queries { return -1 }
		n := int(input[0])
		q := int(input[1])
		if length != usize(2 + n + q) { return -1 }
		mut keys := [max_keys]i64{}
		mut queries := [max_queries]i64{}
		for i in 0 .. n {
			keys[i] = input[2 + i]
			if keys[i] < 0 || keys[i] > 65535 { return -1 }
		}
		for i in 1 .. n {
			key := keys[i]
			mut at := i
			for at > 0 && key < keys[at - 1] { keys[at] = keys[at - 1]; at-- }
			keys[at] = key
		}
		for i in 1 .. n { if keys[i] == keys[i - 1] { return -1 } }
		for i in 0 .. q {
			queries[i] = input[2 + n + i]
			if queries[i] < 0 || queries[i] > 65535 { return -1 }
		}
		if n == 0 || q == 0 { return 0 }

		mut prefixes := [levels * max_keys]i64{}
		mut maxima := [levels * max_keys]i64{}
		mut counts := [levels]int{}
		for depth in 0 .. levels {
			row := depth * max_keys
			for i in 0 .. n {
				value := prefix_of(keys[i], depth)
				count := counts[depth]
				if count == 0 || prefixes[row + count - 1] != value {
					prefixes[row + count] = value
					maxima[row + count] = keys[i]
					counts[depth]++
				} else { maxima[row + count - 1] = keys[i] }
			}
		}
		mut checksum := i64(0)
		for i in 0 .. q {
			checksum += i64(i + 1) * (predecessor(prefixes, maxima, counts, queries[i]) + 1)
		}
		return checksum
	}
}
