package difference_array

import "core:c"

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
difference_array :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	raw_n, raw_q := input[0], input[1]
	if raw_n < 1 || raw_n > 64 || raw_q < 0 || raw_q > 64 do return -1
	n, q := int(raw_n), int(raw_q)
	if length != c.size_t(2+n+3*q) do return -1
	for i := 0; i < n; i += 1 { if input[2+i] < -1_000_000 || input[2+i] > 1_000_000 do return -1 }
	for u := 0; u < q; u += 1 {
		base := 2+n+3*u
		if input[base] < 0 || input[base] >= raw_n || input[base+1] < input[base] || input[base+1] >= raw_n || input[base+2] < -1_000_000 || input[base+2] > 1_000_000 do return -1
	}
	bytes := n*8
	if output == nil || capacity < c.size_t(bytes) do return -2
	var diff: [65]i64
	diff[0] = input[2]
	for i := 1; i < n; i += 1 { diff[i] = input[2+i] - input[2+i-1] }
	for u := 0; u < q; u += 1 {
		base := 2+n+3*u
		left, right, delta := int(input[base]), int(input[base+1]), input[base+2]
		diff[left] += delta
		diff[right+1] -= delta
	}
	current := diff[0]
	put_i64_le(output, 0, current)
	for i := 1; i < n; i += 1 { current += diff[i]; put_i64_le(output, i*8, current) }
	return i64(bytes)
}
