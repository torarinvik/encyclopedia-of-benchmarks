module heap_sort

fn sift_down(mut values &i64, root usize, end usize) {
	mut current := root
	for current < end / 2 {
		mut child := current * 2 + 1
		if child + 1 < end && unsafe { values[child] < values[child + 1] } {
			child++
		}
		if unsafe { values[current] >= values[child] } {
			break
		}
		unsafe {
			temporary := values[current]
			values[current] = values[child]
			values[child] = temporary
		}
		current = child
	}
}

@[export: 'heap_sort']
pub fn heap_sort(mut values &i64, length usize) {
	mut start := length / 2
	for start > 0 {
		start--
		sift_down(mut values, start, length)
	}
	mut end := length
	for end > 1 {
		end--
		unsafe {
			temporary := values[0]
			values[0] = values[end]
			values[end] = temporary
		}
		sift_down(mut values, 0, end)
	}
}
