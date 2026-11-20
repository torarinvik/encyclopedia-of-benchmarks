package y_fast_trie_static_predecessor

import "core:c"

MAX_KEYS :: 256
MAX_QUERIES :: 256
UNIVERSE_BITS :: 16
BUCKET_SIZE :: 16
MAX_BUCKETS :: MAX_KEYS / BUCKET_SIZE
MAX_TRIE_NODES :: 1 + MAX_BUCKETS*UNIVERSE_BITS
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(515)

Trie_Node :: struct {
	child: [2]int,
	min_rank: int,
	leaf_rank: int,
}

lower_bound :: proc "contextless" (keys: ^[MAX_KEYS]i64, low_input, high_input: int, query: i64) -> int {
	low, high := low_input, high_input
	for low < high {
		middle := low + (high - low) / 2
		if keys[middle] < query do low = middle + 1 else high = middle
	}
	return low
}

successor_bucket :: proc "contextless" (nodes: ^[MAX_TRIE_NODES]Trie_Node,
		bucket_count: int, query: i64) -> int {
	node := 0
	best_successor := -1
	path_alive := true
	for bit := UNIVERSE_BITS - 1; bit >= 0; bit -= 1 {
		direction := int((query >> u64(bit)) & 1)
		if direction == 0 {
			right := nodes[node].child[1]
			if right >= 0 do best_successor = nodes[right].min_rank
		}
		next := nodes[node].child[direction]
		if next < 0 { path_alive = false; break }
		node = next
	}
	if path_alive && nodes[node].leaf_rank >= 0 do return nodes[node].leaf_rank
	if best_successor >= 0 do return best_successor
	return bucket_count - 1
}

@(export)
y_fast_trie_static_predecessor :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	key_count_value, query_count_value := input[0], input[1]
	if key_count_value < 0 || key_count_value > MAX_KEYS ||
		query_count_value < 0 || query_count_value > MAX_QUERIES do return -1
	key_count, query_count := int(key_count_value), int(query_count_value)
	if length != c.size_t(2 + key_count + query_count) do return -1

	var keys: [MAX_KEYS]i64
	for index := 0; index < key_count; index += 1 {
		keys[index] = input[2+index]
		if keys[index] < 0 || keys[index] > 65535 do return -1
	}
	for index := 1; index < key_count; index += 1 {
		key := keys[index]
		position := index
		for position > 0 && key < keys[position-1] { keys[position] = keys[position-1]; position -= 1 }
		keys[position] = key
	}
	for index := 1; index < key_count; index += 1 { if keys[index] == keys[index-1] do return -1 }
	for index := 0; index < query_count; index += 1 {
		query := input[2+key_count+index]
		if query < 0 || query > 65535 do return -1
	}
	if key_count == 0 || query_count == 0 do return 0

	bucket_count := (key_count + BUCKET_SIZE - 1) / BUCKET_SIZE
	var nodes: [MAX_TRIE_NODES]Trie_Node
	for index := 0; index < MAX_TRIE_NODES; index += 1 {
		nodes[index].child = [-1, -1]
		nodes[index].min_rank = -1
		nodes[index].leaf_rank = -1
	}
	node_count := 1
	for bucket := 0; bucket < bucket_count; bucket += 1 {
		bucket_start := bucket * BUCKET_SIZE
		bucket_end := min(bucket_start + BUCKET_SIZE, key_count)
		separator := keys[bucket_end-1]
		node := 0
		if nodes[node].min_rank < 0 { nodes[node].min_rank = bucket }
		for bit := UNIVERSE_BITS - 1; bit >= 0; bit -= 1 {
			direction := int((separator >> u64(bit)) & 1)
			next := nodes[node].child[direction]
			if next < 0 {
				next = node_count
				node_count += 1
				nodes[node].child[direction] = next
				nodes[next].child = [-1, -1]
				nodes[next].min_rank = -1
				nodes[next].leaf_rank = -1
			}
			node = next
			if nodes[node].min_rank < 0 { nodes[node].min_rank = bucket }
		}
		nodes[node].leaf_rank = bucket
	}

	checksum: i64 = 0
	for query_index := 0; query_index < query_count; query_index += 1 {
		query := input[2+key_count+query_index]
		bucket := successor_bucket(&nodes, bucket_count, query)
		bucket_start := bucket * BUCKET_SIZE
		bucket_end := min(bucket_start + BUCKET_SIZE, key_count)
		position := lower_bound(&keys, bucket_start, bucket_end, query)

		predecessor: i64 = -1
		if position > bucket_start { predecessor = keys[position-1] }
		else if bucket > 0 { predecessor = keys[bucket_start-1] }

		successor_index := position
		if successor_index < bucket_end && keys[successor_index] == query { successor_index += 1 }
		successor: i64 = -1
		if successor_index < bucket_end { successor = keys[successor_index] }
		else if bucket+1 < bucket_count { successor = keys[bucket_end] }

		checksum += i64(query_index+1) * ((predecessor+1) + 65537*(successor+1))
	}
	return checksum
}
