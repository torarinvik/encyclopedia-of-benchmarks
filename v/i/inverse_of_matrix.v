import math

@[noinline]
fn rounded_multiply(left f64, right f64) f64 { return left * right }

@[noinline]
fn rounded_subtract(left f64, right f64) f64 { return left - right }

@[noinline]
fn rounded_divide(left f64, right f64) f64 { return left / right }

fn valid_dominance(matrix [9]f64, n int) bool {
	mut seen := [3]bool{}
	for row in 0 .. n {
		mut dominant := -1
		for column in 0 .. n {
			mut other_sum := f64(0)
			for other in 0 .. n { if other != column { other_sum += math.abs(matrix[row*n+other]) } }
			if math.abs(matrix[row*n+column]) > other_sum {
				if dominant >= 0 { return false }
				dominant = column
			}
		}
		if dominant < 0 || seen[dominant] { return false }
		seen[dominant] = true
	}
	return true
}

fn invert(mut matrix [9]f64, n int) [9]f64 {
	mut inverse := [9]f64{}
	mut identity := [9]f64{}
	mut index := [3]int{}
	mut scale := [3]f64{}
	for row in 0 .. n {
		index[row] = row
		identity[row*n+row] = 1
		for column in 0 .. n { scale[row] = math.max(scale[row], math.abs(matrix[row*n+column])) }
	}
	for column in 0 .. n-1 {
		mut best_ratio := f64(0)
		mut pivot_slot := column
		for slot in column .. n {
			row := index[slot]
			ratio := rounded_divide(math.abs(matrix[row*n+column]), scale[row])
			if ratio > best_ratio { best_ratio = ratio; pivot_slot = slot }
		}
		index[column], index[pivot_slot] = index[pivot_slot], index[column]
		pivot_row := index[column]
		for slot in column+1 .. n {
			row := index[slot]
			ratio := rounded_divide(matrix[row*n+column], matrix[pivot_row*n+column])
			matrix[row*n+column] = ratio
			for trailing in column+1 .. n {
				product := rounded_multiply(ratio, matrix[pivot_row*n+trailing])
				matrix[row*n+trailing] = rounded_subtract(matrix[row*n+trailing], product)
			}
		}
	}
	for pivot in 0 .. n-1 {
		for slot in pivot+1 .. n {
			row := index[slot]
			pivot_row := index[pivot]
			for rhs in 0 .. n {
				product := rounded_multiply(matrix[row*n+pivot], identity[pivot_row*n+rhs])
				identity[row*n+rhs] = rounded_subtract(identity[row*n+rhs], product)
			}
		}
	}
	for rhs in 0 .. n {
		last_row := index[n-1]
		inverse[(n-1)*n+rhs] = rounded_divide(identity[last_row*n+rhs], matrix[last_row*n+n-1])
		for row in 0 .. n-1 {
			source_row := index[n-2-row]
			actual_row := n-2-row
			mut value := identity[source_row*n+rhs]
			for column in actual_row+1 .. n {
				product := rounded_multiply(matrix[source_row*n+column], inverse[column*n+rhs])
				value = rounded_subtract(value, product)
			}
			inverse[actual_row*n+rhs] = rounded_divide(value, matrix[source_row*n+actual_row])
		}
	}
	return inverse
}

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'inverse_of_matrix']
pub fn inverse_of_matrix(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 11 { return -1 }
		if input[0] != 2 && input[0] != 3 { return -1 }
		n := int(input[0])
		if length != usize(1+n*n) { return -1 }
		mut matrix := [9]f64{}
		for i in 0 .. n*n {
			q := input[i+1]
			if q < -32 || q > 32 { return -1 }
			matrix[i] = f64(q) / 16.0
		}
		if !valid_dominance(matrix, n) { return -1 }
		inverse := invert(mut matrix, n)
		for i in 0 .. n*n { if !inverse[i].is_finite() || math.abs(inverse[i]) > 32768 { return -1 } }
		bytes := n*n*8
		if output == nil || capacity < usize(bytes) { return -2 }
		for i in 0 .. n*n { put_f64_le(mut output, i*8, inverse[i]) }
		return i64(bytes)
	}
}
