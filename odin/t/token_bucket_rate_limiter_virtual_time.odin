package token_bucket_rate_limiter_virtual_time

import "core:c"

MAX_REQUESTS :: 63
MAX_INPUT :: 66

@(export)
token_bucket_rate_limiter_virtual_time :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	capacity, rate, qv := input[0], input[1], input[2]
	if capacity < 0 || capacity > 64 || rate < 0 || rate > 32 || qv < 0 || qv > MAX_REQUESTS || length != c.size_t(3 + qv) do return -1
	q := int(qv)
	for i in 0..<q {
		if input[3 + i] < 0 || input[3 + i] > 256 do return -1
	}

	tokens := capacity
	allowed := u64(0)
	for i in 0..<q {
		tokens += input[3 + i] * rate
		if tokens > capacity do tokens = capacity
		if tokens > 0 {
			allowed |= u64(1) << u64(i)
			tokens -= 1
		}
	}
	return i64(allowed)
}
