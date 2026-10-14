module merge_sort

// Stable bottom-up merge sort using caller-provided scratch storage.
@[export: 'merge_sort']
pub fn merge_sort(mut values &i64, mut scratch &i64, length usize) {
	mut width := usize(1)
	for width < length {
		mut low := usize(0)
		for low < length {
			mut middle := low + width
			if middle > length {
				middle = length
			}
			mut high := middle + width
			if high > length {
				high = length
			}
			mut left := low
			mut right := middle
			mut output := low
			for left < middle && right < high {
				unsafe {
					if values[left] <= values[right] {
						scratch[output] = values[left]
						left++
					} else {
						scratch[output] = values[right]
						right++
					}
				}
				output++
			}
			for left < middle {
				unsafe { scratch[output] = values[left] }
				left++
				output++
			}
			for right < high {
				unsafe { scratch[output] = values[right] }
				right++
				output++
			}
			for index := low; index < high; index++ {
				unsafe { values[index] = scratch[index] }
			}
			low = high
		}
		if width > length / 2 {
			break
		}
		width *= 2
	}
}
