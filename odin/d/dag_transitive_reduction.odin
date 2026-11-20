package dag_transitive_reduction

import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_LENGTH :: 58

@(export)
dag_transitive_reduction :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_LENGTH + 1) do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M do return -1
	n := int(input[0])
	m := int(input[1])
	if length != c.size_t(2 + 2*m) do return -1

	var outgoing: [MAX_N]int
	for edge := 0; edge < m; edge += 1 {
		tail_value := input[2 + 2*edge]
		head_value := input[3 + 2*edge]
		if tail_value < 0 || head_value < 0 || tail_value >= i64(n) || head_value >= i64(n) || tail_value == head_value do return -1
		tail := int(tail_value)
		head := int(head_value)
		bit := 1 << head
		if (outgoing[tail] & bit) != 0 do return -1
		outgoing[tail] |= bit
	}

	var reach: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 do reach[vertex] = outgoing[vertex]
	for middle := 0; middle < n; middle += 1 {
		for source := 0; source < n; source += 1 {
			if (reach[source] & (1 << middle)) != 0 do reach[source] |= reach[middle]
		}
	}
	for vertex := 0; vertex < n; vertex += 1 do if (reach[vertex] & (1 << vertex)) != 0 do return -1

	retained: i64 = 0
	for edge := 0; edge < m; edge += 1 {
		tail := int(input[2 + 2*edge])
		head := int(input[3 + 2*edge])
		redundant := false
		for middle := 0; middle < n; middle += 1 {
			if middle != tail && middle != head &&
				(outgoing[tail] & (1 << middle)) != 0 && (reach[middle] & (1 << head)) != 0 {
				redundant = true
			}
		}
		if !redundant do retained += 1
	}
	return retained
}
