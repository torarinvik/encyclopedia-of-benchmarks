module merge_sort_nr

@[export: 'merge_sort_nr']
pub fn merge_sort_nr(mut values &i64, length usize) {
	if length > 1024 {
		return
	}
	mut scratch := [1024]i64{}
	mut width := usize(1)
	for width < length {
		mut start := usize(0)
		for start < length {
			mut middle := start + width
			if middle > length {
				middle = length
			}
			mut end_index := middle + width
			if end_index > length {
				end_index = length
			}
			mut left := start
			mut right := middle
			mut output := start
			for left < middle && right < end_index {
				if unsafe { values[left] <= values[right] } {
					scratch[output] = unsafe { values[left] }
					left++
				} else {
					scratch[output] = unsafe { values[right] }
					right++
				}
				output++
			}
			for left < middle {
				scratch[output] = unsafe { values[left] }
				left++
				output++
			}
			for right < end_index {
				scratch[output] = unsafe { values[right] }
				right++
				output++
			}
			start += width * 2
		}
		for index in usize(0) .. length {
			unsafe { values[index] = scratch[index] }
		}
		width *= 2
	}
}
