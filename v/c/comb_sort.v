module comb_sort

fn shrink_gap(gap usize) usize {
	return (gap / 13) * 10 + ((gap % 13) * 10) / 13
}

// Comb sort with a rational 10/13 gap shrink factor.
@[export: 'comb_sort']
pub fn comb_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	mut gap := length
	mut swapped := true
	for gap > 1 || swapped {
		gap = shrink_gap(gap)
		if gap < 1 {
			gap = 1
		}
		swapped = false
		mut index := usize(0)
		for index < length - gap {
			if unsafe { values[index] } > unsafe { values[index + gap] } {
				temporary := unsafe { values[index] }
				unsafe {
					values[index] = values[index + gap]
					values[index + gap] = temporary
				}
				swapped = true
			}
			index++
		}
	}
}
