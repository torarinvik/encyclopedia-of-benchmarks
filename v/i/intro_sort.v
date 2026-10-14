module intro_sort

fn swap_i64(mut values &i64, left usize, right usize) {
	temporary := unsafe { values[left] }
	unsafe {
		values[left] = values[right]
		values[right] = temporary
	}
}

fn insertion_sort_range(mut values &i64, low usize, high usize) {
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

fn sift_down(mut values &i64, start usize, count usize, root_start usize) {
	mut root := root_start
	for root < count / 2 {
		mut child := root * 2 + 1
		if child + 1 < count && unsafe { values[start + child] } < unsafe { values[start + child + 1] } {
			child++
		}
		if unsafe { values[start + root] } >= unsafe { values[start + child] } {
			return
		}
		swap_i64(mut values, start + root, start + child)
		root = child
	}
}

fn heap_sort_range(mut values &i64, low usize, count usize) {
	mut parent := count / 2
	for parent > 0 {
		parent--
		sift_down(mut values, low, count, parent)
	}
	mut ending := count
	for ending > 1 {
		ending--
		swap_i64(mut values, low, low + ending)
		sift_down(mut values, low, ending, 0)
	}
}

fn partition_range(mut values &i64, low usize, high usize) usize {
	last := high - 1
	pivot_index := low + (high - low) / 2
	swap_i64(mut values, pivot_index, last)
	pivot := unsafe { values[last] }
	mut boundary := low
	mut probe := low
	for probe < last {
		if unsafe { values[probe] } <= pivot {
			swap_i64(mut values, boundary, probe)
			boundary++
		}
		probe++
	}
	swap_i64(mut values, boundary, last)
	return boundary
}

fn intro_sort_range(mut values &i64, low usize, high usize, depth usize) {
	count := high - low
	if count <= 16 {
		insertion_sort_range(mut values, low, high)
		return
	}
	if depth == 0 {
		heap_sort_range(mut values, low, count)
		return
	}
	pivot := partition_range(mut values, low, high)
	intro_sort_range(mut values, low, pivot, depth - 1)
	intro_sort_range(mut values, pivot + 1, high, depth - 1)
}

fn depth_limit(length usize) usize {
	mut remaining := length
	mut logarithm := usize(0)
	for remaining > 1 {
		remaining /= 2
		logarithm++
	}
	return logarithm * 2
}

// Introsort with quicksort partitioning, a heapsort depth fallback, and insertion cutoff.
@[export: 'intro_sort']
pub fn intro_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	intro_sort_range(mut values, 0, length, depth_limit(length))
}
