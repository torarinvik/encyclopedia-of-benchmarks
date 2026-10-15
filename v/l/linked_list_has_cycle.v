module linked_list_has_cycle

// Floyd cycle detection over a portable successor-index representation.
fn valid_successors(next &i64, length usize) bool {
	if length > 100000 { return false }
	for index in 0 .. length {
		value := unsafe { next[index] }
		if value < -1 || value >= i64(length) { return false }
	}
	return true
}

fn successor(next &i64, node i64) i64 {
	if node < 0 { return -1 }
	return unsafe { next[int(node)] }
}

// Entries are next-node indices; -1 means null and node 0 is the head.
@[export: 'linked_list_has_cycle']
pub fn linked_list_has_cycle(next &i64, length usize) i64 {
	if !valid_successors(next, length) { return -1 }
	if length == 0 { return 0 }
	mut slow := i64(0)
	mut fast := i64(0)
	for fast >= 0 {
		first := successor(next, fast)
		if first < 0 { break }
		slow = successor(next, slow)
		fast = successor(next, first)
		if slow == fast { return 1 }
	}
	return 0
}
