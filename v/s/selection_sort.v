module selection_sort

// In-place selection sort for the shared sorting contract.
@[export: 'selection_sort']
pub fn selection_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
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
		if minimum != index {
			temporary := unsafe { values[index] }
			unsafe {
				values[index] = values[minimum]
				values[minimum] = temporary
			}
		}
		index++
	}
}
