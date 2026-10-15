module linked_list_cycle_entry

// Floyd cycle-entry search over a portable successor-index representation.
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

// Returns the cycle-entry node index, -1 when acyclic, and -2 for malformed input.
@[export: 'linked_list_cycle_entry']
pub fn linked_list_cycle_entry(next &i64, length usize) i64 {
	if !valid_successors(next, length) { return -2 }
	if length == 0 { return -1 }
	mut slow := i64(0)
	mut fast := i64(0)
	mut meeting := false
	for fast >= 0 {
		first := successor(next, fast)
		if first < 0 { break }
		slow = successor(next, slow)
		fast = successor(next, first)
		if slow == fast { meeting = true; break }
	}
	if !meeting { return -1 }
	mut entry := i64(0)
	for entry != slow {
		entry = successor(next, entry)
		slow = successor(next, slow)
	}
	return entry
}
