module bubble_sort

// Stable bubble sort for the shared mutable in-place sorting contract.
@[export: 'bubble_sort']
pub fn bubble_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	mut end_index := length
	for end_index > 1 {
		mut swapped := false
		mut index := usize(0)
		for index + 1 < end_index {
			if unsafe { values[index] } > unsafe { values[index + 1] } {
				temporary := unsafe { values[index] }
				unsafe {
					values[index] = values[index + 1]
					values[index + 1] = temporary
				}
				swapped = true
			}
			index++
		}
		if !swapped {
			break
		}
		end_index--
	}
}
