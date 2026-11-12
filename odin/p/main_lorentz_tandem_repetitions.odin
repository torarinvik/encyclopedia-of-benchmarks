package main_lorentz_tandem_repetitions

import "core:c"

N :: 24
MAX_REPETITIONS :: N * N / 4
INPUT_MAX :: N + 1
Z_MAX :: 2 * N + 1

ml_min :: proc(a, b: int) -> int { if a < b { return a }; return b }
ml_max :: proc(a, b: int) -> int { if a > b { return a }; return b }

ml_z_values :: proc(text: [^]i64, length: int, z: [^]int) {
	for i in 0..<length { z[i] = 0 }
	left, right := 0, 0
	has_box := false
	for i in 1..<length {
		if has_box && i <= right { z[i] = ml_min(right-i+1, z[i-left]) }
		for i+z[i] < length && text[z[i]] == text[i+z[i]] { z[i] += 1 }
		if !has_box || i+z[i]-1 > right { left, right, has_box = i, i+z[i]-1, true }
	}
}

ml_z_at :: proc(z: [^]int, length, index: int) -> int {
	if index < length { return z[index] }
	return 0
}

ml_divide :: proc(symbols: [^]i64, offset, length: int, marked: [^]bool) {
	if length <= 1 { return }
	left_size := length / 2
	right_size := length - left_size
	middle := offset + left_size
	buffer: [Z_MAX]i64
	z: [Z_MAX]int
	before, after: [N]int
	ml_divide(symbols, offset, left_size, marked)
	ml_divide(symbols, middle, right_size, marked)

	for i in 0..<left_size { buffer[i] = symbols[middle-1-i] }
	ml_z_values(&buffer[0], left_size, &z[0])
	for center in 0..<left_size { before[center] = ml_z_at(&z[0], left_size, left_size-center) }

	used := 0
	for i in 0..<right_size { buffer[used] = symbols[middle+i]; used += 1 }
	buffer[used] = -1; used += 1
	for i in 0..<left_size { buffer[used] = symbols[offset+i]; used += 1 }
	ml_z_values(&buffer[0], used, &z[0])
	for center in 0..<left_size { after[center] = ml_z_at(&z[0], used, right_size+1+center) }

	for i in 0..<left_size { buffer[i] = symbols[middle-1-i] }
	used = left_size; buffer[used] = -1; used += 1
	for i in 0..<right_size { buffer[used] = symbols[offset+length-1-i]; used += 1 }
	ml_z_values(&buffer[0], used, &z[0])
	for d in 0..<right_size { before[left_size+d] = ml_z_at(&z[0], used, left_size+1+right_size-1-d) }

	for i in 0..<right_size { buffer[i] = symbols[middle+i] }
	ml_z_values(&buffer[0], right_size, &z[0])
	for d in 0..<right_size { after[left_size+d] = ml_z_at(&z[0], right_size, d+1) }

	for center in 0..<length {
		left_biased := center < left_size
		half := left_size-center
		if !left_biased { half = center-left_size+1 }
		if before[center]+after[center] < half { continue }
		low := ml_max(1, half-after[center]); high := ml_min(half, before[center])
		for first_half := low; first_half <= high; first_half += 1 {
			if left_biased && first_half == half { continue }
			start := center-half-first_half+1
			if left_biased { start = center-first_half }
			marked[(offset+start)*(N+1)+half] = true
		}
	}
}

ml_store :: proc(out: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for i in 0..<8 { out[offset+i] = u8((bits >> (8*i)) & 255) }
}

@(export)
main_lorentz_tandem_repetitions :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > INPUT_MAX do return -1
	nr := input[0]
	if nr < 0 || nr > N || length != c.size_t(nr+1) do return -1
	n := int(nr)
	symbols: [N]i64
	for i in 0..<n { symbols[i] = input[i+1]; if symbols[i] < 0 || symbols[i] > 255 do return -1 }
	marked: [N*(N+1)]bool
	ml_divide(&symbols[0], 0, n, &marked[0])
	codes: [MAX_REPETITIONS]i64
	count := 0
	for start := 0; start < n; start += 1 {
		for half := 1; half <= n/2; half += 1 {
			if start+2*half <= n && marked[start*(N+1)+half] { codes[count] = i64(start*32+half); count += 1 }
		}
	}
	required := 8*(count+1)
	if output == nil || capacity < c.size_t(required) do return -2
	ml_store(output, 0, i64(count))
	for i in 0..<count { ml_store(output, 8*(i+1), codes[i]) }
	return i64(required)
}
