package odd_even_jump_reachability_count

import "core:c"

MAX_N :: 64
MAX_PARSEABLE :: 66

comes_before :: proc "contextless" (input: [^]i64, left, right: int, descending: bool) -> bool {
	left_value := input[left + 1]
	right_value := input[right + 1]
	if left_value != right_value do return if descending then left_value > right_value else left_value < right_value
	return left < right
}

build_successors :: proc "contextless" (input: [^]i64, n: int, descending: bool, target: [^]i64) {
	order: [MAX_N]int
	stack: [MAX_N]int
	for i := 0; i < n; i += 1 { order[i] = i; target[i] = -1 }
	for i := 1; i < n; i += 1 {
		key := order[i]
		position := i
		for position > 0 && comes_before(input, key, order[position - 1], descending) {
			order[position] = order[position - 1]
			position -= 1
		}
		order[position] = key
	}
	stack_size := 0
	for i := 0; i < n; i += 1 {
		index := order[i]
		for stack_size > 0 && stack[stack_size - 1] < index {
			stack_size -= 1
			target[stack[stack_size]] = i64(index)
		}
		stack[stack_size] = index
		stack_size += 1
	}
}

@(export)
odd_even_jump_reachability_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE) do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(n + 1) do return -1
	for i := 0; i < n; i += 1 {
		if input[i + 1] < -1000000 || input[i + 1] > 1000000 do return -1
	}
	var odd_next: [MAX_N]i64
	var even_next: [MAX_N]i64
	build_successors(input, n, false, &odd_next[0])
	build_successors(input, n, true, &even_next[0])
	var odd: [MAX_N]bool
	var even: [MAX_N]bool
	odd[n - 1] = true
	even[n - 1] = true
	for i := n - 1; i > 0; {
		i -= 1
		if odd_next[i] >= 0 do odd[i] = even[int(odd_next[i])]
		if even_next[i] >= 0 do even[i] = odd[int(even_next[i])]
	}
	count := i64(0)
	for i := 0; i < n; i += 1 { if odd[i] do count += 1 }
	return count
}
