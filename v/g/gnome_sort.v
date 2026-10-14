module gnome_sort

// Stable gnome sort for the shared mutable in-place sorting contract.
@[export: 'gnome_sort']
pub fn gnome_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	mut position := usize(1)
	for position < length {
		if unsafe { values[position] } >= unsafe { values[position - 1] } {
			position++
		} else {
			temporary := unsafe { values[position - 1] }
			unsafe {
				values[position - 1] = values[position]
				values[position] = temporary
			}
			if position > 1 {
				position--
			} else {
				position = 1
			}
		}
	}
}
