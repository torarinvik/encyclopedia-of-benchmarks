module quick_sort_iterative

fn quick_sort_iterative_partition(mut values &i64, low usize, high usize) usize {
	pivot := unsafe { values[high - 1] }
	mut boundary := low
	for scan := low; scan < high - 1; scan++ {
		if unsafe { values[scan] } <= pivot {
			temporary := unsafe { values[boundary] }
			unsafe {
				values[boundary] = values[scan]
				values[scan] = temporary
			}
			boundary++
		}
	}
	temporary := unsafe { values[boundary] }
	unsafe {
		values[boundary] = values[high - 1]
		values[high - 1] = temporary
	}
	return boundary
}

@[export: 'quick_sort_iterative']
pub fn quick_sort_iterative(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	mut stack_low := [128]usize{}
	mut stack_high := [128]usize{}
	mut stack_size := usize(0)
	mut low := usize(0)
	mut high := length
	for {
		for high - low > 1 {
			pivot := quick_sort_iterative_partition(mut values, low, high)
			left_size := pivot - low
			right_size := high - pivot - 1
			if left_size < right_size {
				if right_size > 1 {
					stack_low[stack_size] = pivot + 1
					stack_high[stack_size] = high
					stack_size++
				}
				high = pivot
			} else {
				if left_size > 1 {
					stack_low[stack_size] = low
					stack_high[stack_size] = pivot
					stack_size++
				}
				low = pivot + 1
			}
		}
		if stack_size == 0 {
			break
		}
		stack_size--
		low = stack_low[stack_size]
		high = stack_high[stack_size]
	}
}
