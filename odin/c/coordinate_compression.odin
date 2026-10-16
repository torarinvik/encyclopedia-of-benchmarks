package coordinate_compression

import "core:c"

put_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
	bits := transmute(u64)value
	for byte: usize = 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
coordinate_compression :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || input[0] < 0 || input[0] > 128 do return -1
	n := int(input[0])
	if length != c.size_t(n + 1) do return -1
	var sorted: [128]i64
	for i := 0; i < n; i += 1 {
		value := input[i+1]
		if value < -2147483648 || value > 2147483647 do return -1
		sorted[i] = value
	}
	if capacity < c.size_t(n*8) || (n > 0 && output == nil) do return -2
	for i := 1; i < n; i += 1 {
		value := sorted[i]
		j := i
		for j > 0 && sorted[j-1] > value { sorted[j] = sorted[j-1]; j -= 1 }
		sorted[j] = value
	}
	var ranks: [128]i64
	rank: i64 = -1
	for i := 0; i < n; i += 1 {
		if i == 0 || sorted[i] != sorted[i-1] do rank += 1
		ranks[i] = rank
	}
	for i := 0; i < n; i += 1 {
		low := 0
		high := n
		for low < high {
			middle := low + (high-low)/2
			if sorted[middle] < input[i+1] do low = middle + 1 else do high = middle
		}
		put_i64_le(output, usize(i*8), ranks[low])
	}
	return i64(n*8)
}
