module reverse_selection

@[export: 'reverse_selection']
pub fn reverse_selection(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	for start := usize(0); start + 1 < length; start++ {
		mut minimum := start
		for scan := start + 1; scan < length; scan++ {
			if unsafe { values[scan] } < unsafe { values[minimum] } {
				minimum = scan
			}
		}
		mut left := start
		mut right := minimum
		for left < right {
			temporary := unsafe { values[left] }
			unsafe {
				values[left] = values[right]
				values[right] = temporary
			}
			left++
			right--
		}
	}
}
