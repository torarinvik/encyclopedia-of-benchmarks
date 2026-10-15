module is_sorted

@[export: 'is_sorted']
pub fn is_sorted(values &i64, length usize) i64 {
	if length > 4096 || (length > 0 && unsafe { values == nil }) { return -1 }
	unsafe {
		for index in 0 .. length {
			if values[index] < -2147483648 || values[index] > 2147483647 { return -1 }
		}
		for index in 1 .. length {
			if values[index] < values[index - 1] { return 0 }
		}
	}
	return 1
}
