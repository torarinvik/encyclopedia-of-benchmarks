module random_pivot_quick_sort

fn random_pivot_quick_sort_next31(mut state &u64) u64 {
	unsafe {
		state[0] = (state[0] * u64(48271)) % u64(2147483647)
		return state[0]
	}
}

fn random_pivot_quick_sort_next(mut state &u64) u64 {
	high := random_pivot_quick_sort_next31(mut state)
	low := random_pivot_quick_sort_next31(mut state)
	return high * u64(2147483647) + low
}

fn random_pivot_quick_sort_partition(mut values &i64, low usize, high usize, mut state &u64) usize {
	width := high - low
	pivot_index := low + usize(random_pivot_quick_sort_next(mut state) % u64(width))
	pivot_value := unsafe { values[pivot_index] }
	pivot_slot := unsafe { values[high - 1] }
	unsafe {
		values[high - 1] = pivot_value
		values[pivot_index] = pivot_slot
	}
	mut boundary := low
	for scan := low; scan < high - 1; scan++ {
		if unsafe { values[scan] } < pivot_value {
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

@[export: 'random_pivot_quick_sort']
pub fn random_pivot_quick_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	mut stack_low := [128]usize{}
	mut stack_high := [128]usize{}
	mut stack_size := usize(0)
	mut low := usize(0)
	mut high := length
	mut random_state := u64(1)
	for {
		for high - low > 1 {
			pivot := random_pivot_quick_sort_partition(mut values, low, high, mut random_state)
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
