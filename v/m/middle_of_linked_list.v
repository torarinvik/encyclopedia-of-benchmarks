module middle_of_linked_list

const max_nodes = 100000

@[export: 'middle_of_linked_list']
pub fn middle_of_linked_list(next &i64, length usize) i64 {
	if length > max_nodes { return -2 }
	unsafe {
		for index in 0 .. length {
			if next[index] < -1 || next[index] >= i64(length) { return -2 }
		}
		if length == 0 { return -1 }
		mut slow := i64(0)
		mut fast := i64(0)
		for fast >= 0 {
			first := next[usize(fast)]
			if first < 0 { break }
			slow = next[usize(slow)]
			fast = next[usize(first)]
			if slow == fast { return -2 }
		}
		slow = 0
		fast = 0
		for fast >= 0 {
			first := next[usize(fast)]
			if first < 0 { break }
			slow = next[usize(slow)]
			fast = next[usize(first)]
		}
		return slow
	}
}
