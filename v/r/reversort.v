module reversort

@[export: 'reversort']
pub fn reversort(mut values &i64, length usize) {
	if length < 2 { return }
	mut index := usize(0)
	for index + 1 < length {
		mut minimum := index
		mut probe := index + 1
		for probe < length {
			if unsafe { values[probe] } < unsafe { values[minimum] } {
				minimum = probe
			}
			probe++
		}
		mut left := index
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
		index++
	}
}
