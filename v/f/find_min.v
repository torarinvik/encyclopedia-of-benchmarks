module find_min

// Return the smallest signed value in a nonempty array.
@[export: 'find_min']
pub fn find_min(values &i64, length usize) i64 {
	if length == 0 || length > 512 { return -1 }
	mut result := unsafe { values[0] }
	for index in 1 .. length {
		value := unsafe { values[index] }
		if value < result { result = value }
	}
	return result
}
