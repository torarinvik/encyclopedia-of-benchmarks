module find_duplicate_number

// Find the cycle entrance induced by the duplicate value.
@[export: 'find_duplicate_number']
pub fn find_duplicate_number(values &i64, length usize) i64 {
	if length < 2 || length > 100001 { return -1 }
	maximum_value := length - 1
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < 1 || u64(value) > u64(maximum_value) { return -1 }
	}

	mut slow := usize(unsafe { values[0] })
	mut fast := slow
	for {
		slow = usize(unsafe { values[slow] })
		fast_index := usize(unsafe { values[fast] })
		fast = usize(unsafe { values[fast_index] })
		if slow == fast { break }
	}

	slow = usize(unsafe { values[0] })
	for slow != fast {
		slow = usize(unsafe { values[slow] })
		fast = usize(unsafe { values[fast] })
	}
	return i64(slow)
}
