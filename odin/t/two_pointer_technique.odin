package two_pointer_technique

import "core:c"

MAX_INPUT :: 132

next_node :: proc(node, n, cycle_target: i64) -> i64 {
	if node < 0 do return -1
	if node + 1 < n do return node + 1
	return cycle_target
}

@(export)
two_pointer_technique :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	op, n, cycle_target, k := input[0], input[1], input[2], input[3]
	if n < 0 || n > 128 || length != c.size_t(4 + n) do return -1
	if (n == 0 && cycle_target != -1) || (n > 0 && (cycle_target < -1 || cycle_target >= n)) do return -1
	for i in 0..<int(n) {
		if input[4 + i] < -1000000 || input[4 + i] > 1000000 do return -1
	}

	if op == 0 {
		if k != 0 do return -1
		slow := i64(0)
		if n == 0 do slow = -1
		fast := slow
		for fast != -1 {
			slow = next_node(slow, n, cycle_target)
			fast = next_node(fast, n, cycle_target)
			if fast != -1 do fast = next_node(fast, n, cycle_target)
			if slow == -1 || fast == -1 do break
			if slow == fast do return 1
		}
		return 0
	}
	if op == 1 {
		if cycle_target != -1 || k != 0 do return -1
		if n == 0 do return -2
		slow, fast := i64(0), i64(0)
		for fast != -1 {
			fast = next_node(fast, n, cycle_target)
			if fast == -1 do break
			fast = next_node(fast, n, cycle_target)
			slow = next_node(slow, n, cycle_target)
		}
		return input[4 + int(slow)] + 1000001
	}
	if op == 2 {
		if cycle_target != -1 || k < 1 || k > n do return -1
		lead, lag := i64(0), i64(0)
		for i := i64(0); i < k; i += 1 { lead = next_node(lead, n, cycle_target) }
		for lead != -1 {
			lead = next_node(lead, n, cycle_target)
			lag = next_node(lag, n, cycle_target)
		}
		return input[4 + int(lag)] + 3000002
	}
	return -1
}
