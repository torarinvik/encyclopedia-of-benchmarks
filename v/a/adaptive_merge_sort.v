module adaptive_merge_sort

fn merge_range(mut values &i64, mut scratch &i64, low usize, high usize) {
	if high - low <= 1 { return }
	middle := low + (high - low) / 2
	merge_range(mut values, mut scratch, low, middle)
	merge_range(mut values, mut scratch, middle, high)
	if unsafe { values[middle - 1] <= values[middle] } { return }
	mut left := low
	mut right := middle
	mut output := low
	for left < middle && right < high {
		if unsafe { values[left] <= values[right] } {
			unsafe { scratch[output] = values[left] }
			left++
		} else {
			unsafe { scratch[output] = values[right] }
			right++
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
	for index in low .. high {
		unsafe { values[index] = scratch[index] }
	}
}

@[export: 'adaptive_merge_sort']
pub fn adaptive_merge_sort(mut values &i64, length usize) {
	if length > 1024 { return }
	mut scratch := [1024]i64{}
	merge_range(mut values, mut scratch[0], 0, length)
}
