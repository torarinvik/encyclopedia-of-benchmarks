module tim_sort

const tim_sort_run = usize(32)

// Stable bottom-up TimSort-style sort using caller-provided scratch storage.
fn insertion_sort_run(mut values &i64, low usize, high usize) {
	mut index := low + 1
	for index < high {
		key := unsafe { values[index] }
		mut cursor := index
		for cursor > low && unsafe { values[cursor - 1] } > key {
			unsafe { values[cursor] = values[cursor - 1] }
			cursor--
		}
		unsafe { values[cursor] = key }
		index++
	}
}

fn merge_runs(mut values &i64, mut scratch &i64, left usize, middle usize, right usize) {
	mut index := left
	for index < right {
		unsafe { scratch[index] = values[index] }
		index++
	}
	mut first := left
	mut second := middle
	mut output := left
	for output < right {
		if first == middle {
			unsafe { values[output] = scratch[second] }
			second++
		} else if second == right || unsafe { scratch[first] } <= unsafe { scratch[second] } {
			unsafe { values[output] = scratch[first] }
			first++
		} else {
			unsafe { values[output] = scratch[second] }
			second++
		}
		output++
	}
}

@[export: 'tim_sort']
pub fn tim_sort(mut values &i64, mut scratch &i64, length usize) {
	if length < 2 {
		return
	}
	mut start := usize(0)
	for start < length {
		remaining := length - start
		ending := if remaining < tim_sort_run { length } else { start + tim_sort_run }
		insertion_sort_run(mut values, start, ending)
		start = ending
	}

	mut width := tim_sort_run
	for width < length {
		mut left := usize(0)
		for left < length {
			left_remaining := length - left
			middle := left + (if width < left_remaining { width } else { left_remaining })
			right_remaining := length - middle
			right := middle + (if width < right_remaining { width } else { right_remaining })
			if middle < right {
				merge_runs(mut values, mut scratch, left, middle, right)
			}
			left = right
		}
		if width >= length - width {
			break
		}
		width *= 2
	}
}
