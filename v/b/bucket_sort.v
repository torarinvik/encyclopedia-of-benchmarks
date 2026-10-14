module bucket_sort

fn bucket_order_key(value i64) u64 {
	sign_bit := u64(1) << 63
	if value < 0 {
		return sign_bit - 1 - u64(-(value + 1))
	}
	return sign_bit + u64(value)
}

fn bucket_sort_insertion(mut values &i64, base usize, low usize, high usize) {
	mut index := low
	if low < high {
		index++
	}
	for index < high {
		key := unsafe { values[base + index] }
		mut position := index
		for position > low {
			should_shift := unsafe { values[base + position - 1] > key }
			if !should_shift {
				break
			}
			unsafe { values[base + position] = values[base + position - 1] }
			position--
		}
		unsafe { values[base + position] = key }
		index++
	}
}

// Stable top-byte bucket sort for signed 64-bit values.
@[export: 'bucket_sort']
pub fn bucket_sort(mut values &i64, mut scratch &i64, length usize) {
	if length < 2 {
		return
	}
	unsafe {
		for bucket := usize(0); bucket < 256; bucket++ {
			scratch[bucket] = 0
		}
		for index := usize(0); index < length; index++ {
			bucket := usize(bucket_order_key(values[index]) >> 56)
			scratch[bucket]++
		}
		mut next := usize(0)
		for bucket := usize(0); bucket < 256; bucket++ {
			count := usize(scratch[bucket])
			scratch[bucket] = i64(next)
			next += count
		}
		for index := usize(0); index < length; index++ {
			bucket := usize(bucket_order_key(values[index]) >> 56)
			destination := usize(scratch[bucket])
			scratch[bucket]++
			scratch[256 + destination] = values[index]
		}
		mut low := usize(0)
		for bucket := usize(0); bucket < 256; bucket++ {
			high := usize(scratch[bucket])
			bucket_sort_insertion(scratch, 256, low, high)
			low = high
		}
		for index := usize(0); index < length; index++ {
			values[index] = scratch[256 + index]
		}
	}
}
