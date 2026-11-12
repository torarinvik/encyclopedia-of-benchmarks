package functional_graph_cycle_parameters

import "core:c"

MAX_N :: i64(64)
ENCODING_BASE :: i64(65)

next_node :: proc(input: [^]i64, node: i64) -> i64 {
	return input[2 + int(node)]
}

@(export)
functional_graph_cycle_parameters :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 66 do return -1
	n, start := input[0], input[1]
	if n < 1 || n > MAX_N || start < 0 || start >= n || length != c.size_t(n + 2) do return -1
	for i := 0; i < int(n); i += 1 {
		successor := input[2 + i]
		if successor < 0 || successor >= n do return -1
	}

	tortoise := next_node(input, start)
	hare := next_node(input, next_node(input, start))
	for tortoise != hare {
		tortoise = next_node(input, tortoise)
		hare = next_node(input, next_node(input, hare))
	}
	mu := i64(0)
	tortoise = start
	for tortoise != hare {
		tortoise = next_node(input, tortoise)
		hare = next_node(input, hare)
		mu += 1
	}
	lambda := i64(1)
	hare = next_node(input, tortoise)
	for hare != tortoise {
		hare = next_node(input, hare)
		lambda += 1
	}
	return ENCODING_BASE * mu + lambda
}
