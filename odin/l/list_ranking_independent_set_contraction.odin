package list_ranking_independent_set_contraction

import "core:c"

MAX_N :: 16
MAX_INPUT :: 34
MAX_OUTPUT :: 128

put64 :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[position + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
list_ranking_independent_set_contraction :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n64, head64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_N || length != c.size_t(2 + 2*n64) ||
		head64 < 0 || head64 >= n64 do return -1
	n, head := int(n64), int(head64)
	weight: [MAX_N]i64
	successor: [MAX_N]i64
	indegree: [MAX_N]int
	tail_count := 0
	for node := 0; node < n; node += 1 {
		weight[node] = input[2 + node]
		successor[node] = input[2 + n + node]
		if weight[node] < 1 || weight[node] > 10000 || successor[node] < -1 || successor[node] >= n64 do return -1
		if successor[node] == -1 {
			tail_count += 1
		} else {
			next := int(successor[node])
			indegree[next] += 1
			if indegree[next] > 1 do return -1
		}
	}
	if tail_count != 1 || indegree[head] != 0 do return -1

	path: [MAX_N]int
	seen: [MAX_N]bool
	path_length := 0
	node := head64
	for node != -1 {
		index := int(node)
		if seen[index] || path_length == n do return -1
		seen[index] = true
		path[path_length] = index
		path_length += 1
		node = successor[index]
	}
	if path_length != n do return -1
	output_bytes := 8*n
	if output == nil || capacity < c.size_t(output_bytes) do return -2

	removed_node: [MAX_N]int
	removed_successor: [MAX_N]int
	old_successor_weight: [MAX_N]i64
	removed_count := 0
	for path_length > 1 {
		counts: [3]int
		for position := 0; position+1 < path_length; position += 1 {
			counts[position%3] += 1
		}
		color := 0
		for candidate := 1; candidate < 3; candidate += 1 {
			if counts[candidate] > counts[color] { color = candidate }
		}
		write := 0
		for position := 0; position < path_length; position += 1 {
			current := path[position]
			if position+1 < path_length && position%3 == color {
				next := path[position+1]
				removed_node[removed_count] = current
				removed_successor[removed_count] = next
				old_successor_weight[removed_count] = weight[next]
				removed_count += 1
				weight[next] += weight[current]
			} else {
				path[write] = current
				write += 1
			}
		}
		if write == path_length do return -1
		path_length = write
	}

	rank: [MAX_N]i64
	rank[path[0]] = weight[path[0]]
	for removed_count > 0 {
		removed_count -= 1
		current, next := removed_node[removed_count], removed_successor[removed_count]
		rank[current] = rank[next] - old_successor_weight[removed_count]
	}
	staged: [MAX_OUTPUT]u8
	for index := 0; index < n; index += 1 { put64(&staged[0], 8*index, rank[index]) }
	for index := 0; index < output_bytes; index += 1 { output[index] = staged[index] }
	return i64(output_bytes)
}
