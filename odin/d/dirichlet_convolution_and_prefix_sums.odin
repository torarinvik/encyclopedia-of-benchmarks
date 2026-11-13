package dirichlet_convolution_and_prefix_sums

import "core:c"

MAX_N :: 64
MAX_Q :: 15
MAX_PARSEABLE :: 32
MODULUS :: i64(998244353)

prefix_value :: proc(q, prefix: [MAX_Q]i64, count: int, value: i64) -> i64 {
	if value == 0 do return 0
	for i := 0; i < count; i += 1 {
		if q[i] == value do return prefix[i]
	}
	return 0
}

store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
dirichlet_convolution_and_prefix_sums :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_PARSEABLE) do return -1
	if input[0] < 1 || input[0] > i64(MAX_N) do return -1
	n := input[0]
	var descending: [MAX_Q]i64
	count := 0
	left := i64(1)
	for left <= n {
		value := n / left
		descending[count] = value
		count += 1
		left = n / value + 1
	}
	var q, f, g, result: [MAX_Q]i64
	for i := 0; i < count; i += 1 {
		q[i] = descending[count - 1 - i]
	}
	if length != c.size_t(1 + 2 * count) do return -1
	for i := 0; i < count; i += 1 {
		f[i] = input[1 + i]
		g[i] = input[1 + count + i]
		if f[i] < 1 || f[i] >= MODULUS || g[i] < 1 || g[i] >= MODULUS do return -1
	}
	needed := c.size_t(8 * count)
	if output == nil || output_capacity < needed do return -2

	for out := 0; out < count; out += 1 {
		x := q[out]
		total := i64(0)
		left = 1
		for left <= x {
			quotient := x / left
			right := x / quotient
			below := x / (quotient + 1)
			interval := (prefix_value(q, f, count, right) - prefix_value(q, f, count, below)) % MODULUS
			if interval < 0 do interval += MODULUS
			q_index := 0
			for q_index < count && q[q_index] != quotient do q_index += 1
			if q_index == count do return -1
			total = (total + interval * g[q_index]) % MODULUS
			left = right + 1
		}
		result[out] = total
	}
	for i := 0; i < count; i += 1 {
		store_le(output, 8 * i, result[i])
	}
	return i64(needed)
}
