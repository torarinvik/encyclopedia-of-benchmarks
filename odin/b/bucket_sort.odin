package bucket_sort

import "core:c"

bucket_order_key :: proc(value: i64) -> u64 {
	sign_bit := u64(1) << 63
	if value < 0 {
		return sign_bit - 1 - u64(-(value + 1))
	}
	return sign_bit + u64(value)
}

bucket_sort_insertion :: proc(values: [^]i64, base, low, high: c.size_t) {
	index := low
	if low < high {
		index += 1
	}
	for index < high {
		key := values[base + index]
		position := index
		for position > low && values[base + position - 1] > key {
			values[base + position] = values[base + position - 1]
			position -= 1
		}
		values[base + position] = key
		index += 1
	}
}

@(export)
bucket_sort :: proc "c" (values, scratch: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	for bucket := c.size_t(0); bucket < 256; bucket += 1 {
		scratch[bucket] = 0
	}
	for index := c.size_t(0); index < length; index += 1 {
		bucket := c.size_t(bucket_order_key(values[index]) >> 56)
		scratch[bucket] += 1
	}
	next := c.size_t(0)
	for bucket := c.size_t(0); bucket < 256; bucket += 1 {
		count := c.size_t(scratch[bucket])
		scratch[bucket] = i64(next)
		next += count
	}
	for index := c.size_t(0); index < length; index += 1 {
		bucket := c.size_t(bucket_order_key(values[index]) >> 56)
		destination := c.size_t(scratch[bucket])
		scratch[bucket] += 1
		scratch[256 + destination] = values[index]
	}
	low := c.size_t(0)
	for bucket := c.size_t(0); bucket < 256; bucket += 1 {
		high := c.size_t(scratch[bucket])
		bucket_sort_insertion(scratch, 256, low, high)
		low = high
	}
	for index := c.size_t(0); index < length; index += 1 {
		values[index] = scratch[256 + index]
	}
}
