package xor_linear_basis

import "core:c"

MAX_OPERATIONS :: 64
MAX_INSERTIONS :: 16
MAX_INPUT_VALUES :: 1 + 2 * MAX_OPERATIONS
BIT_COUNT :: 63

insert_value :: proc "contextless" (basis: ^[BIT_COUNT]u64, value: u64) {
	reduced := value
	for bit := BIT_COUNT - 1; bit >= 0 && reduced != 0; bit -= 1 {
		if ((reduced >> bit) & 1) == 0 do continue
		if basis[bit] == 0 { basis[bit] = reduced; return }
		reduced ^= basis[bit]
	}
}

maximum_value :: proc "contextless" (basis: [BIT_COUNT]u64) -> u64 {
	best: u64 = 0
	for bit := BIT_COUNT - 1; bit >= 0; bit -= 1 {
		candidate := best ^ basis[bit]
		if candidate > best do best = candidate
	}
	return best
}

contains_value :: proc "contextless" (basis: [BIT_COUNT]u64, raw_value: u64) -> bool {
	value := raw_value
	for bit := BIT_COUNT - 1; bit >= 0; bit -= 1 {
		if ((value >> bit) & 1) == 0 do continue
		if basis[bit] == 0 do return false
		value ^= basis[bit]
	}
	return value == 0
}

store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> (8 * byte)) & 255)
	}
}

@(export)
xor_linear_basis :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	qv := input[0]
	if qv < 1 || qv > MAX_OPERATIONS do return -1
	q := int(qv)

	var basis: [BIT_COUNT]u64
	var results: [MAX_OPERATIONS]i64
	result_count, cursor, insertion_count := 0, 1, 0
	for _ := 0; _ < q; _ += 1 {
		if c.size_t(cursor) >= length do return -1
		kind := input[cursor]
		cursor += 1
		if kind == 0 || kind == 2 {
			if c.size_t(cursor) >= length do return -1
			raw := input[cursor]
			cursor += 1
			if raw < 0 do return -1
			value := u64(raw)
			if kind == 0 {
				insertion_count += 1
				if insertion_count > MAX_INSERTIONS do return -1
				insert_value(&basis, value)
			} else {
				if contains_value(basis, value) { results[result_count] = 1 } else { results[result_count] = 0 }
				result_count += 1
			}
		} else if kind == 1 {
			results[result_count] = i64(maximum_value(basis))
			result_count += 1
		} else {
			return -1
		}
	}
	if c.size_t(cursor) != length do return -1
	output_bytes := c.size_t(result_count * 8)
	if output_bytes == 0 do return 0
	if output == nil || capacity < output_bytes do return -2
	for result := 0; result < result_count; result += 1 {
		store_le(output, result * 8, results[result])
	}
	return i64(output_bytes)
}
