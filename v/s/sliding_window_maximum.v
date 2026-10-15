module sliding_window_maximum

const max_length = 1024

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'sliding_window_maximum']
pub fn sliding_window_maximum(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_length + 2 { return -1 }
	n_value := unsafe { input[0] }; k_value := unsafe { input[1] }
	if n_value < 0 || n_value > max_length || k_value < 1 || k_value > max_length { return -1 }
	n := int(n_value); k := int(k_value)
	if int(length) != n + 2 { return -1 }
	for i in 0 .. n { value := unsafe { input[2+i] }; if value < -2147483648 || value > 2147483647 { return -1 } }
	windows := if n >= k { n - k + 1 } else { 0 }
	if int(capacity) < windows * 8 || (windows > 0 && unsafe { output == nil }) { return -2 }
	mut deque := [max_length]int{}
	mut head := 0; mut tail := 0; mut out_index := 0
	for i in 0 .. n {
		for head < tail && deque[head] + k <= i { head++ }
		for head < tail && unsafe { input[2+deque[tail-1]] < input[2+i] } { tail-- }
		deque[tail] = i; tail++
		if i + 1 >= k { store_i64_le(output, out_index * 8, unsafe { input[2+deque[head]] }); out_index++ }
	}
	return i64(windows)
}
