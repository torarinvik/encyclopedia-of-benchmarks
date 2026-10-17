@[noinline]
fn rounded_multiply(left f64, right f64) f64 { return left * right }
@[noinline]
fn rounded_add(left f64, right f64) f64 { return left + right }
@[noinline]
fn rounded_subtract(left f64, right f64) f64 { return left - right }
@[noinline]
fn rounded_divide(left f64, right f64) f64 { return left / right }

fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

@[export: 'lu_decompose']
pub fn lu_decompose(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 18 { return -1 }
		if !exact_integer(input[0], 1, 4) { return -1 }
		n := int(input[0])
		if input_length != usize(1+n*n) { return -1 }
		mut matrix := [16]f64{}
		for i in 0 .. n*n {
			if !exact_integer(input[i+1], -8, 8) { return -1 }
			matrix[i] = input[i+1]
		}
		mut lower := [16]f64{}
		mut upper := [16]f64{}
		for row in 0 .. n {
			for column in row .. n {
				mut sum := f64(0)
				for index in 0 .. row {
					product := rounded_multiply(lower[row*n+index], upper[index*n+column])
					sum = rounded_add(sum, product)
				}
				upper[row*n+column] = rounded_subtract(matrix[row*n+column], sum)
			}
			pivot := upper[row*n+row]
			if pivot == 0 || !pivot.is_finite() { return -1 }
			lower[row*n+row] = 1.0
			for lower_row in row+1 .. n {
				mut sum := f64(0)
				for index in 0 .. row {
					product := rounded_multiply(lower[lower_row*n+index], upper[index*n+row])
					sum = rounded_add(sum, product)
				}
				numerator := rounded_subtract(matrix[lower_row*n+row], sum)
				value := rounded_divide(numerator, pivot)
				if !value.is_finite() { return -1 }
				lower[lower_row*n+row] = value
			}
		}
		for i in 0 .. n*n { if !lower[i].is_finite() || !upper[i].is_finite() { return -1 } }
		output_length := 2*n*n
		if output == nil || capacity < usize(output_length) { return -2 }
		for i in 0 .. n*n { output[i] = lower[i] }
		for i in 0 .. n*n { output[n*n+i] = upper[i] }
		return i64(output_length)
	}
}
