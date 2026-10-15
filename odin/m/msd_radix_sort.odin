package msd_radix_sort

import "core:c"

msd_order_key :: proc "contextless" (value: i64) -> u64 {
	sign_bit := u64(1) << 63
	if value < 0 {
		return sign_bit - 1 - u64(-(value + 1))
	}
	return sign_bit + u64(value)
}

msd_sort_range :: proc "contextless" (values: [^]i64, begin, end: c.size_t, bit: i32) {
	if end - begin < 2 || bit < 0 {
		return
	}
	left := begin
	right := end
	for left < right {
		for left < right && ((msd_order_key(values[left]) >> u32(bit)) & 1) == 0 {
			left += 1
		}
		for left < right && ((msd_order_key(values[right - 1]) >> u32(bit)) & 1) != 0 {
			right -= 1
		}
		if left < right {
			temporary := values[left]
			values[left] = values[right - 1]
			values[right - 1] = temporary
			left += 1
			right -= 1
		}
	}
	msd_sort_range(values, begin, left, bit - 1)
	msd_sort_range(values, left, end, bit - 1)
}

@(export)
msd_radix_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > 1 {
		msd_sort_range(values, 0, length, 63)
	}
}
