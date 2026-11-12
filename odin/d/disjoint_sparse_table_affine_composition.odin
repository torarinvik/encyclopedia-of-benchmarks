package disjoint_sparse_table_affine_composition

import "core:c"

MODULUS :: i64(1_000_000_007)
MAX_N :: 32
MAX_Q :: 32
MAX_LEVELS :: 5

Affine :: struct { a, b: i64 }

combine :: proc "contextless" (left, right: Affine) -> Affine {
	return { (right.a * left.a) % MODULUS, (right.a * left.b + right.b) % MODULUS }
}

put_word :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(byte * 8))
	}
}

@(export)
disjoint_sparse_table_affine_composition :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 130 do return -1
	unsafe {
		n_value, q_value := input[0], input[1]
		if n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q do return -1
		n, q := int(n_value), int(q_value)
		if int(length) != 2 + 2*n + 2*q do return -1

		var maps: [MAX_N]Affine
		var left, right: [MAX_Q]int
		cursor := 2
		for index := 0; index < n; index += 1 {
			a, b := input[cursor], input[cursor + 1]
			cursor += 2
			if a < 0 || a >= MODULUS || b < 0 || b >= MODULUS do return -1
			maps[index] = {a, b}
		}
		for query := 0; query < q; query += 1 {
			lo, hi := input[cursor], input[cursor + 1]
			cursor += 2
			if lo < 0 || lo > hi || hi >= n_value do return -1
			left[query], right[query] = int(lo), int(hi)
		}
		output_bytes := q * 16
		if output == nil || capacity < c.size_t(output_bytes) do return -2

		var table: [MAX_LEVELS][MAX_N]Affine
		levels, span := 0, 1
		for span < n { levels += 1; span *= 2 }
		for level := 0; level < levels; level += 1 {
			half := 1 << level
			width := half * 2
			for start := 0; start < n; start += width {
				middle, ending := start + half, start + width
				if middle > n do middle = n
				if ending > n do ending = n
				if middle > start {
					table[level][middle - 1] = maps[middle - 1]
					for index := middle - 1; index > start; index -= 1 {
						table[level][index - 1] = combine(maps[index - 1], table[level][index])
					}
				}
				if middle < ending {
					table[level][middle] = maps[middle]
					for index := middle + 1; index < ending; index += 1 {
						table[level][index] = combine(table[level][index - 1], maps[index])
					}
				}
			}
		}
		for query := 0; query < q; query += 1 {
			var answer: Affine
			if left[query] == right[query] {
				answer = maps[left[query]]
			} else {
				difference := left[query] ^ right[query]
				level := 0
				for difference > 1 { difference >>= 1; level += 1 }
				answer = combine(table[level][left[query]], table[level][right[query]])
			}
			put_word(output, query * 16, answer.a)
			put_word(output, query * 16 + 8, answer.b)
		}
		return i64(output_bytes)
	}
}
