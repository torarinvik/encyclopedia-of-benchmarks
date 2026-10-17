package inverse_of_matrix

import "core:c"
import "core:math"

rounded_multiply :: #force_no_inline proc "contextless" (left, right: f64) -> f64 { return left * right }
rounded_subtract :: #force_no_inline proc "contextless" (left, right: f64) -> f64 { return left - right }
rounded_divide :: #force_no_inline proc "contextless" (left, right: f64) -> f64 { return left / right }

valid_dominance :: proc(matrix: [9]f64, n: int) -> bool {
	seen: [3]bool
	for row := 0; row < n; row += 1 {
		dominant := -1
		for column := 0; column < n; column += 1 {
			other_sum := f64(0)
			for other := 0; other < n; other += 1 {
				if other != column do other_sum += math.abs(matrix[row*n+other])
			}
			if math.abs(matrix[row*n+column]) > other_sum {
				if dominant >= 0 do return false
				dominant = column
			}
		}
		if dominant < 0 || seen[dominant] do return false
		seen[dominant] = true
	}
	return true
}

invert :: proc(matrix: ^[9]f64, n: int) -> [9]f64 {
	inverse: [9]f64
	identity: [9]f64
	index: [3]int
	scale: [3]f64
	for row := 0; row < n; row += 1 {
		index[row] = row
		identity[row*n+row] = 1
		for column := 0; column < n; column += 1 {
			scale[row] = max(scale[row], math.abs(matrix[row*n+column]))
		}
	}
	for column := 0; column < n-1; column += 1 {
		best_ratio := f64(0)
		pivot_slot := column
		for slot := column; slot < n; slot += 1 {
			row := index[slot]
			ratio := rounded_divide(math.abs(matrix[row*n+column]), scale[row])
			if ratio > best_ratio { best_ratio = ratio; pivot_slot = slot }
		}
		index[column], index[pivot_slot] = index[pivot_slot], index[column]
		pivot_row := index[column]
		for slot := column+1; slot < n; slot += 1 {
			row := index[slot]
			ratio := rounded_divide(matrix[row*n+column], matrix[pivot_row*n+column])
			matrix[row*n+column] = ratio
			for trailing := column+1; trailing < n; trailing += 1 {
				product := rounded_multiply(ratio, matrix[pivot_row*n+trailing])
				matrix[row*n+trailing] = rounded_subtract(matrix[row*n+trailing], product)
			}
		}
	}
	for pivot := 0; pivot < n-1; pivot += 1 {
		for slot := pivot+1; slot < n; slot += 1 {
			row := index[slot]; pivot_row := index[pivot]
			for rhs := 0; rhs < n; rhs += 1 {
				product := rounded_multiply(matrix[row*n+pivot], identity[pivot_row*n+rhs])
				identity[row*n+rhs] = rounded_subtract(identity[row*n+rhs], product)
			}
		}
	}
	for rhs := 0; rhs < n; rhs += 1 {
		last_row := index[n-1]
		inverse[(n-1)*n+rhs] = rounded_divide(identity[last_row*n+rhs], matrix[last_row*n+n-1])
		for row := n-2; row >= 0; row -= 1 {
			source_row := index[row]
			value := identity[source_row*n+rhs]
			for column := row+1; column < n; column += 1 {
				product := rounded_multiply(matrix[source_row*n+column], inverse[column*n+rhs])
				value = rounded_subtract(value, product)
			}
			inverse[row*n+rhs] = rounded_divide(value, matrix[source_row*n+row])
		}
	}
	return inverse
}

put_f64_le :: proc(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> (8*byte)) & 255) }
}

@(export)
inverse_of_matrix :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 11 do return -1
	if input[0] != 2 && input[0] != 3 do return -1
	n := int(input[0])
	if length != c.size_t(1+n*n) do return -1
	matrix: [9]f64
	for i := 0; i < n*n; i += 1 {
		q := input[i+1]
		if q < -32 || q > 32 do return -1
		matrix[i] = f64(q) / 16
	}
	if !valid_dominance(matrix, n) do return -1
	inverse := invert(&matrix, n)
	for i := 0; i < n*n; i += 1 {
		if math.is_nan(inverse[i]) || math.is_inf(inverse[i]) || math.abs(inverse[i]) > 32768 do return -1
	}
	bytes := n*n*8
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < n*n; i += 1 { put_f64_le(output, i*8, inverse[i]) }
	return i64(bytes)
}
