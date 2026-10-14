module radix_sort

fn radix_order_key(value i64) u64 {
	sign_bit := u64(1) << 63
	if value < 0 {
		return sign_bit - 1 - u64(-(value + 1))
	}
	return sign_bit + u64(value)
}

// Stable LSD radix sort for signed 64-bit values.
@[export: 'radix_sort']
pub fn radix_sort(mut values &i64, mut scratch &i64, length usize) {
	if length < 2 {
		return
	}
	unsafe {
		for pass := 0; pass < 8; pass++ {
			for bucket := usize(0); bucket < 256; bucket++ {
				scratch[bucket] = 0
			}
			shift := pass * 8
			for index := usize(0); index < length; index++ {
				bucket := usize((radix_order_key(values[index]) >> shift) & 255)
				scratch[bucket]++
			}
			mut next := usize(0)
			for bucket := usize(0); bucket < 256; bucket++ {
				count := usize(scratch[bucket])
				scratch[bucket] = i64(next)
				next += count
			}
			for index := usize(0); index < length; index++ {
				bucket := usize((radix_order_key(values[index]) >> shift) & 255)
				destination := usize(scratch[bucket])
				scratch[bucket]++
				scratch[256 + destination] = values[index]
			}
			for index := usize(0); index < length; index++ {
				values[index] = scratch[256 + index]
			}
		}
	}
}
