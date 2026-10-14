module cycle_sort

// Cycle sort aims to minimize writes while placing each item at its rank.
@[export: 'cycle_sort']
pub fn cycle_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	mut cycle_start := usize(0)
	for cycle_start < length - 1 {
		mut item := unsafe { values[cycle_start] }
		mut position := cycle_start
		for scan := cycle_start + 1; scan < length; scan++ {
			if unsafe { values[scan] < item } {
				position++
			}
		}
		if position != cycle_start {
			for position < length && unsafe { item == values[position] } {
				position++
			}
			if position < length {
				unsafe {
					temporary := values[position]
					values[position] = item
					item = temporary
				}
				for position != cycle_start {
					position = cycle_start
					for scan := cycle_start + 1; scan < length; scan++ {
						if unsafe { values[scan] < item } {
							position++
						}
					}
					for position < length && unsafe { item == values[position] } {
						position++
					}
					if position == length {
						break
					}
					unsafe {
						temporary := values[position]
						values[position] = item
						item = temporary
					}
				}
			}
		}
		cycle_start++
	}
}
