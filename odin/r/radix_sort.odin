package radix_sort

import "core:c"

radix_order_key :: proc(value: i64) -> u64 {
	sign_bit := u64(1) << 63
	if value < 0 {
		return sign_bit - 1 - u64(-(value + 1))
	}
	return sign_bit + u64(value)
}

@(export)
radix_sort :: proc "c" (values, scratch: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	for pass := 0; pass < 8; pass += 1 {
		for bucket := c.size_t(0); bucket < 256; bucket += 1 {
			scratch[bucket] = 0
		}
		shift := pass * 8
		for index := c.size_t(0); index < length; index += 1 {
			bucket := c.size_t((radix_order_key(values[index]) >> shift) & 255)
			scratch[bucket] += 1
		}
		next := c.size_t(0)
		for bucket := c.size_t(0); bucket < 256; bucket += 1 {
			count := c.size_t(scratch[bucket])
			scratch[bucket] = i64(next)
			next += count
		}
		for index := c.size_t(0); index < length; index += 1 {
			bucket := c.size_t((radix_order_key(values[index]) >> shift) & 255)
			destination := c.size_t(scratch[bucket])
			scratch[bucket] += 1
			scratch[256 + destination] = values[index]
		}
		for index := c.size_t(0); index < length; index += 1 {
			values[index] = scratch[256 + index]
		}
	}
}
