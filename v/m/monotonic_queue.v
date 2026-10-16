const max_n = 4096
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

fn hash_i32(mut hash u64, value i64) u64 {
	bits := u32(i32(value))
	for shift in 0 .. 4 { hash = (hash ^ u64(u8(bits >> (shift * 8)))) * fnv_prime }
	return hash
}

@[export: 'monotonic_queue']
pub fn monotonic_queue(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_n + 2 { return -1 }
	n64 := unsafe { input[0] }
	window64 := unsafe { input[1] }
	if n64 < 1 || n64 > max_n || window64 < 1 || window64 > n64 || length != usize(n64 + 2) { return -1 }
	n := int(n64)
	window := int(window64)
	for i in 0 .. n {
		value := unsafe { input[2 + i] }
		if value < i64(-2147483648) || value > i64(2147483647) { return -1 }
	}
	mut deque := [max_n]int{}
	mut head := 0
	mut tail := 0
	mut hash := fnv_offset
	for i in 0 .. n {
		for head < tail && deque[head] + window <= i { head++ }
		for head < tail && unsafe { input[2 + deque[tail - 1]] } <= unsafe { input[2 + i] } { tail-- }
		deque[tail] = i
		tail++
		if i + 1 >= window { hash = hash_i32(hash, unsafe { input[2 + deque[head]] }) }
	}
	return i64(hash & u64(0x7fffffffffffffff))
}
