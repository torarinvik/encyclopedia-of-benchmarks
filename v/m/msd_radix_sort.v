module msd_radix_sort

fn msd_order_key(value i64) u64 {
	sign_bit := u64(1) << 63
	if value < 0 {
		return sign_bit - 1 - u64(-(value + 1))
	}
	return sign_bit + u64(value)
}

fn msd_sort_range(mut values &i64, begin_index usize, end_index usize, bit_position int) {
	if end_index - begin_index < 2 || bit_position < 0 {
		return
	}
	mut left := begin_index
	mut right := end_index
	unsafe {
		for left < right {
			for left < right && ((msd_order_key(values[left]) >> bit_position) & 1) == 0 {
				left++
			}
			for left < right && ((msd_order_key(values[right - 1]) >> bit_position) & 1) != 0 {
				right--
			}
			if left < right {
				temporary := values[left]
				values[left] = values[right - 1]
				values[right - 1] = temporary
				left++
				right--
			}
		}
	}
	msd_sort_range(mut values, begin_index, left, bit_position - 1)
	msd_sort_range(mut values, left, end_index, bit_position - 1)
}

@[export: 'msd_radix_sort']
pub fn msd_radix_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	msd_sort_range(mut values, 0, length, 63)
}
