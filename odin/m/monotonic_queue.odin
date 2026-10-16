package monotonic_queue

import "core:c"

FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

hash_i32 :: proc(hash: u64, value: i64) -> u64 {
	bits := transmute(u32(i32(value)))
	result := hash
	for shift := 0; shift < 32; shift += 8 { result = (result ^ u64(u8(bits >> u32(shift)))) * FNV_PRIME }
	return result
}

@(export)
monotonic_queue :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 4098 do return -1
	n64, window64 := input[0], input[1]
	if n64 < 1 || n64 > 4096 || window64 < 1 || window64 > n64 || length != c.size_t(n64 + 2) do return -1
	n, window := int(n64), int(window64)
	for i := 0; i < n; i += 1 { if input[2+i] < -2147483648 || input[2+i] > 2147483647 do return -1 }
	var deque: [4096]int
	head, tail := 0, 0
	hash := FNV_OFFSET
	for i := 0; i < n; i += 1 {
		for head < tail && deque[head] + window <= i { head += 1 }
		for head < tail && input[2+deque[tail-1]] <= input[2+i] { tail -= 1 }
		deque[tail] = i; tail += 1
		if i+1 >= window { hash = hash_i32(hash, input[2+deque[head]]) }
	}
	return i64(hash & 0x7fffffffffffffff)
}
