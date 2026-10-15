package sliding_window_maximum

import "core:c"

MAX_LENGTH :: 1024
store_i64_le :: proc "c" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
sliding_window_maximum :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_LENGTH + 2 do return -1
	n_value, k_value := input[0], input[1]
	if n_value < 0 || n_value > MAX_LENGTH || k_value < 1 || k_value > MAX_LENGTH do return -1
	n, k := int(n_value), int(k_value)
	if int(length) != n + 2 do return -1
	for i := 0; i < n; i += 1 { if input[2+i] < -2147483648 || input[2+i] > 2147483647 do return -1 }
	windows := 0; if n >= k { windows = n - k + 1 }
	if int(capacity) < windows * 8 || (windows > 0 && output == nil) do return -2
	deque: [MAX_LENGTH]int
	head, tail, out_index := 0, 0, 0
	for i := 0; i < n; i += 1 {
		for head < tail && deque[head] + k <= i { head += 1 }
		for head < tail && input[2+deque[tail-1]] < input[2+i] { tail -= 1 }
		deque[tail] = i; tail += 1
		if i + 1 >= k { store_i64_le(output, out_index*8, input[2+deque[head]]); out_index += 1 }
	}
	return i64(windows)
}
