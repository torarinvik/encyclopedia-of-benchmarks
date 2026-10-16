module two_pointer_technique

fn next_node(node i64, n i64, cycle_target i64) i64 {
	if node < 0 { return -1 }
	if node + 1 < n { return node + 1 }
	return cycle_target
}

@[export: 'two_pointer_technique']
pub fn two_pointer_technique(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > 132 { return -1 }
	op := unsafe { input[0] }
	n := unsafe { input[1] }
	cycle_target := unsafe { input[2] }
	k := unsafe { input[3] }
	if n < 0 || n > 128 || length != usize(4 + n) { return -1 }
	if (n == 0 && cycle_target != -1) || (n > 0 && (cycle_target < -1 || cycle_target >= n)) { return -1 }
	for i in 0 .. int(n) {
		if unsafe { input[4 + i] < -1000000 || input[4 + i] > 1000000 } { return -1 }
	}

	if op == 0 {
		if k != 0 { return -1 }
		mut slow := i64(0)
		if n == 0 { slow = -1 }
		mut fast := slow
		for fast != -1 {
			slow = next_node(slow, n, cycle_target)
			fast = next_node(fast, n, cycle_target)
			if fast != -1 { fast = next_node(fast, n, cycle_target) }
			if slow == -1 || fast == -1 { break }
			if slow == fast { return 1 }
		}
		return 0
	}
	if op == 1 {
		if cycle_target != -1 || k != 0 { return -1 }
		if n == 0 { return -2 }
		mut slow := i64(0)
		mut fast := i64(0)
		for fast != -1 {
			fast = next_node(fast, n, cycle_target)
			if fast == -1 { break }
			fast = next_node(fast, n, cycle_target)
			slow = next_node(slow, n, cycle_target)
		}
		return unsafe { input[4 + int(slow)] } + 1000001
	}
	if op == 2 {
		if cycle_target != -1 || k < 1 || k > n { return -1 }
		mut lead := i64(0)
		mut lag := i64(0)
		for _ in 0 .. int(k) { lead = next_node(lead, n, cycle_target) }
		for lead != -1 {
			lead = next_node(lead, n, cycle_target)
			lag = next_node(lag, n, cycle_target)
		}
		return unsafe { input[4 + int(lag)] } + 3000002
	}
	return -1
}
