package minkowski_question_mark_rational

import "core:c"

MAX_DENOMINATOR :: i64(1_000_000)
MAX_CF_SUM :: i64(60)

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

cf_sum :: proc "contextless" (numerator, denominator: i64) -> i64 {
	n, d, total := numerator, denominator, i64(0)
	for n != 0 {
		quotient := d / n
		if quotient > MAX_CF_SUM-total do return -1
		total += quotient
		remainder := d % n
		d, n = n, remainder
	}
	return total
}

alternating_numerator :: proc "contextless" (numerator, denominator, total: i64) -> i64 {
	n, d := numerator, denominator
	prefix, index, value := i64(0), i64(1), i64(0)
	for n != 0 {
		quotient := d / n
		prefix += quotient
		shift := int(total - prefix)
		term := i64(1) << shift
		if index % 2 == 1 do value += term else value -= term
		remainder := d % n
		d, n = n, remainder
		index += 1
	}
	return value
}

@(export)
minkowski_question_mark_rational :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 3 do return -1
	if length != 2 do return -1
	p, q := input[0], input[1]
	if p < 0 || q < 1 || q > MAX_DENOMINATOR || p > q do return -1
	total := cf_sum(p, q)
	if total < 0 do return -1
	if output == nil || capacity < 16 do return -2
	value := alternating_numerator(p, q, total)
	exponent := if total == 0 { i64(0) } else { total - 1 }
	store_i64_le(output, 0, value)
	store_i64_le(output, 8, exponent)
	return 16
}
