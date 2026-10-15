module find_the_highest_altitude

@[export: 'find_the_highest_altitude']
pub fn find_the_highest_altitude(input &i64, length usize) i64 {
	if unsafe { input == nil } || length == 0 { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 0 || n_value > 1024 || length != usize(n_value + 1) { return -1 }
	n := int(n_value)
	mut altitude := i64(0); mut maximum := i64(0)
	for i in 0 .. n {
		gain := unsafe { input[i + 1] }
		if gain < -2147483648 || gain > 2147483647 { return -1 }
		altitude += gain
		if altitude > maximum { maximum = altitude }
	}
	return maximum
}
