module dark_sort

@[export: 'dark_sort']
pub fn dark_sort(mut values &i64, length usize) {
	if length < 2 { return }
	mut maximum := unsafe { values[0] }
	mut index := usize(1)
	for index < length {
		if unsafe { values[index] } > maximum { maximum = unsafe { values[index] } }
		index++
	}
	mut counts := [129]i64{}
	index = 0
	for index < length {
		counts[unsafe { values[index] }]++
		index++
	}
	mut output := usize(0)
	mut value := i64(0)
	for value <= maximum {
		for counts[value] > 0 {
			unsafe { values[output] = value }
			output++
			counts[value]--
		}
		value++
	}
}
