package two_square_sum

import "core:c"

MAX_Q :: 8
MAX_N :: i64(10000)
MAX_OUTPUT_BYTES :: 6496

integer_sqrt :: proc(value: i64) -> i64 {
	low, high := i64(0), value + 1
	for high - low > 1 {
		middle := low + (high - low) / 2
		if middle * middle <= value { low = middle } else { high = middle }
	}
	return low
}

write_u32 :: proc(output: [^]u8, offset: int, value: u32) {
	output[offset] = u8(value)
	output[offset + 1] = u8(value >> 8)
	output[offset + 2] = u8(value >> 16)
	output[offset + 3] = u8(value >> 24)
}

@(export)
two_square_sum :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_Q + 1 do return -1
	q64 := input[0]
	if q64 < 1 || q64 > i64(MAX_Q) do return -1
	q := int(q64)
	if length != c.size_t(q + 1) do return -1

	numbers: [MAX_Q]i64
	counts: [MAX_Q]int
	total_pairs := 0
	for query := 0; query < q; query += 1 {
		n := input[query + 1]
		if n < 0 || n > MAX_N do return -1
		numbers[query] = n
		for a := i64(0); a * a <= n; a += 1 {
			remainder := n - a * a
			b := integer_sqrt(remainder)
			if b * b == remainder do counts[query] += 1
		}
		total_pairs += counts[query]
	}

	required := 4 * (q + 2 * total_pairs)
	if output == nil || capacity < c.size_t(required) || required > MAX_OUTPUT_BYTES do return -2
	offset := 0
	for query := 0; query < q; query += 1 {
		write_u32(output, offset, u32(counts[query]))
		offset += 4
		n := numbers[query]
		for a := i64(0); a * a <= n; a += 1 {
			remainder := n - a * a
			b := integer_sqrt(remainder)
			if b * b != remainder do continue
			write_u32(output, offset, u32(a))
			write_u32(output, offset + 4, u32(b))
			offset += 8
		}
	}
	return i64(offset)
}
