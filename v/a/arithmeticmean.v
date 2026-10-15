module arithmeticmean

@[export: 'arithmeticmean']
pub fn arithmeticmean(values &i64, length usize) i64 {
	if length != 2 { return -1 }
	left := unsafe { values[0] }
	right := unsafe { values[1] }
	if left < 0 || left > 9_000_000_000_000_000_000 || right < 0 || right > 9_000_000_000_000_000_000 {
		return -1
	}
	return ((left ^ right) >> 1) + (left & right)
}
