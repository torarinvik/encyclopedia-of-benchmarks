module token_bucket_rate_limiter_virtual_time

const max_requests = 63
const max_input = 66

@[export: 'token_bucket_rate_limiter_virtual_time']
pub fn token_bucket_rate_limiter_virtual_time(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input { return -1 }
	capacity := unsafe { input[0] }
	rate := unsafe { input[1] }
	qv := unsafe { input[2] }
	if capacity < 0 || capacity > 64 || rate < 0 || rate > 32 || qv < 0 || qv > max_requests || length != usize(3 + qv) { return -1 }
	q := int(qv)
	for i in 0 .. q {
		if unsafe { input[3 + i] } < 0 || unsafe { input[3 + i] } > 256 { return -1 }
	}

	mut tokens := capacity
	mut allowed := u64(0)
	for i in 0 .. q {
		ticks := unsafe { input[3 + i] }
		tokens += ticks * rate
		if tokens > capacity { tokens = capacity }
		if tokens > 0 {
			allowed |= u64(1) << u64(i)
			tokens--
		}
	}
	return i64(allowed)
}
