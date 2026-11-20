package arpa_offline_rmq

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MAX_INPUT_VALUES :: 195

@(export)
arpa_offline_rmq :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q do return -1
	n, q := int(n_value), int(q_value)
	if length != c.size_t(2 + n + 2*q) do return -1
	for i := 0; i < n; i += 1 {
		if input[2+i] < -1000 || input[2+i] > 1000 do return -1
	}
	query_start := 2 + n
	for j := 0; j < q; j += 1 {
		left, right := input[query_start+2*j], input[query_start+2*j+1]
		if left < 0 || left > right || right >= n_value do return -1
	}
	parent: [MAX_N]i64
	stack: [MAX_N]i64
	head: [MAX_N]i64
	next_query: [MAX_Q]i64
	for i := 0; i < n; i += 1 { parent[i] = i64(i); head[i] = -1 }
	for j := 0; j < q; j += 1 {
		right := int(input[query_start+2*j+1])
		next_query[j] = head[right]
		head[right] = i64(j)
	}
	stack_size := 0
	checksum := i64(0)
	for right := 0; right < n; right += 1 {
		for stack_size > 0 && input[2+int(stack[stack_size-1])] > input[2+right] {
			stack_size -= 1
			parent[int(stack[stack_size])] = i64(right)
		}
		stack[stack_size] = i64(right)
		stack_size += 1
		query := head[right]
		for query >= 0 {
			ordinal := int(query)
			node := int(input[query_start+2*ordinal])
			root := node
			for int(parent[root]) != root { root = int(parent[root]) }
			for int(parent[node]) != node {
				next := int(parent[node])
				parent[node] = i64(root)
				node = next
			}
			checksum += i64(ordinal+1) * i64(root+1)
			query = next_query[ordinal]
		}
	}
	return checksum
}
