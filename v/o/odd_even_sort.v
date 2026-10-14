module odd_even_sort

// Stable odd-even transposition sort for the shared sorting contract.
@[export: 'odd_even_sort']
pub fn odd_even_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	mut swapped := true
	for swapped {
		swapped = false
		mut index := usize(0)
		for index + 1 < length {
			if unsafe { values[index] } > unsafe { values[index + 1] } {
				temporary := unsafe { values[index] }
				unsafe {
					values[index] = values[index + 1]
					values[index + 1] = temporary
				}
				swapped = true
			}
			index += 2
		}
		index = 1
		for index + 1 < length {
			if unsafe { values[index] } > unsafe { values[index + 1] } {
				temporary := unsafe { values[index] }
				unsafe {
					values[index] = values[index + 1]
					values[index + 1] = temporary
				}
				swapped = true
			}
			index += 2
		}
	}
}
