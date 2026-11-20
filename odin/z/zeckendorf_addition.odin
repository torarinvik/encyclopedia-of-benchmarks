package zeckendorf_addition

import "core:c"

MAX_BITS :: 64
MAX_PARSEABLE :: 131
MAX_OUTPUT :: 66

canonical :: proc(bits: [^]i64, length: usz) -> bool {
	if length == 1 && bits[0] == 0 do return true
	if length == 0 || bits[0] != 1 do return false
	for i := usz(0); i < length; i += 1 {
		if bits[i] != 0 && bits[i] != 1 do return false
		if i + 1 < length && bits[i] == 1 && bits[i + 1] == 1 do return false
	}
	return true
}

stage_one :: proc(d: [^]u8, n: usz) {
	for i := usz(0); i + 3 < n; i += 1 {
		if d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 0 {
			d[i] = 1; d[i + 1] = 0; d[i + 2] = 0; d[i + 3] += 1
		} else if d[i] == 0 && d[i + 1] == 3 && d[i + 2] == 0 {
			d[i] = 1; d[i + 1] = 1; d[i + 2] = 0; d[i + 3] += 1
		} else if d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 1 {
			d[i] = 1; d[i + 1] = 1; d[i + 2] = 0
		} else if d[i] == 0 && d[i + 1] == 1 && d[i + 2] == 2 {
			d[i] = 1; d[i + 1] = 0; d[i + 2] = 1
		}
	}
	if n >= 3 && d[n - 3] == 0 && d[n - 2] == 3 && d[n - 1] == 0 {
		d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 1
	} else if n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 0 {
		d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1
	} else if n >= 4 && d[n - 4] == 0 && d[n - 3] == 1 && d[n - 2] == 2 && d[n - 1] == 0 {
		d[n - 4] = 1; d[n - 3] = 0; d[n - 2] = 1; d[n - 1] = 0
	} else if n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 1 {
		d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 0
	}
	if n >= 2 && d[n - 2] == 0 && d[n - 1] == 3 {
		d[n - 2] = 1; d[n - 1] = 1
	} else if n >= 2 && d[n - 2] == 0 && d[n - 1] == 2 {
		d[n - 2] = 1; d[n - 1] = 0
	} else if n >= 3 && d[n - 3] == 0 && d[n - 2] == 1 && d[n - 1] == 2 {
		d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1
	}
}

@(export)
zeckendorf_addition :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_PARSEABLE do return -1
	first_n := input[0]
	if first_n < 1 || first_n > MAX_BITS do return -1
	first_size := usz(first_n)
	second_n_index := first_size + 1
	if second_n_index >= length do return -1
	second_n := input[second_n_index]
	if second_n < 1 || second_n > MAX_BITS do return -1
	second_size := usz(second_n)
	if length != second_n_index + second_size + 1 do return -1
	first := &input[1]
	second := &input[second_n_index + 1]
	if !canonical(first, first_size) || !canonical(second, second_size) do return -1

	width := first_size
	if second_size > width do width = second_size
	first_offset := width - first_size
	second_offset := width - second_size
	digits: [MAX_OUTPUT]u8 = {}
	digit_count := width + 1
	for i := usz(0); i < width; i += 1 {
		a: u8 = 0
		b: u8 = 0
		if i >= first_offset do a = u8(first[i - first_offset])
		if i >= second_offset do b = u8(second[i - second_offset])
		digits[i + 1] = a + b
	}
	stage_one(&digits[0], digit_count)
	for i := digit_count; i > 0; i -= 1 do digits[i] = digits[i - 1]
	digits[0] = 0
	digit_count += 1
	for i := digit_count - 2; i > 0; i -= 1 {
		start := i - 1
		if digits[start] == 0 && digits[start + 1] == 1 && digits[start + 2] == 1 {
			digits[start] = 1; digits[start + 1] = 0; digits[start + 2] = 0
		}
	}
	for i := usz(0); i + 2 < digit_count; i += 1 {
		if digits[i] == 0 && digits[i + 1] == 1 && digits[i + 2] == 1 {
			digits[i] = 1; digits[i + 1] = 0; digits[i + 2] = 0
		}
	}
	first_output := usz(0)
	for first_output + 1 < digit_count && digits[first_output] == 0 { first_output += 1 }
	required := digit_count - first_output
	if output == nil || output_capacity < required do return -2
	for i := usz(0); i < required; i += 1 do output[i] = u8('0') + digits[first_output + i]
	return i64(required)
}
