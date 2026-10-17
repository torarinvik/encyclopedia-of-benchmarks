module strassen_matrix_multiplication

const max_input_length = 129

fn strassen_multiply(a &i64, b &i64, mut result &i64, n int) {
	if n == 1 {
		unsafe { result[0] = a[0] * b[0] }
		return
	}
	h := n / 2
	mut x := [16]i64{}
	mut y := [16]i64{}
	mut m1 := [16]i64{}
	mut m2 := [16]i64{}
	mut m3 := [16]i64{}
	mut m4 := [16]i64{}
	mut m5 := [16]i64{}
	mut m6 := [16]i64{}
	mut m7 := [16]i64{}
	for r in 0 .. h {
		for col in 0 .. h {
			i := r * h + col
			unsafe {
				x[i] = a[r*n+col] + a[(r+h)*n+col+h]
				y[i] = b[r*n+col] + b[(r+h)*n+col+h]
			}
		}
	}
	strassen_multiply(&x[0], &y[0], mut m1[0], h)
	for r in 0 .. h { for col in 0 .. h {
		i := r * h + col
		unsafe { x[i] = a[(r+h)*n+col] + a[(r+h)*n+col+h]; y[i] = b[r*n+col] }
	} }
	strassen_multiply(&x[0], &y[0], mut m2[0], h)
	for r in 0 .. h { for col in 0 .. h {
		i := r * h + col
		unsafe { x[i] = a[r*n+col]; y[i] = b[r*n+col+h] - b[(r+h)*n+col+h] }
	} }
	strassen_multiply(&x[0], &y[0], mut m3[0], h)
	for r in 0 .. h { for col in 0 .. h {
		i := r * h + col
		unsafe { x[i] = a[(r+h)*n+col+h]; y[i] = b[(r+h)*n+col] - b[r*n+col] }
	} }
	strassen_multiply(&x[0], &y[0], mut m4[0], h)
	for r in 0 .. h { for col in 0 .. h {
		i := r * h + col
		unsafe { x[i] = a[r*n+col] + a[r*n+col+h]; y[i] = b[(r+h)*n+col+h] }
	} }
	strassen_multiply(&x[0], &y[0], mut m5[0], h)
	for r in 0 .. h { for col in 0 .. h {
		i := r * h + col
		unsafe { x[i] = a[(r+h)*n+col] - a[r*n+col]; y[i] = b[r*n+col] + b[r*n+col+h] }
	} }
	strassen_multiply(&x[0], &y[0], mut m6[0], h)
	for r in 0 .. h { for col in 0 .. h {
		i := r * h + col
		unsafe {
			x[i] = a[r*n+col+h] - a[(r+h)*n+col+h]
			y[i] = b[(r+h)*n+col] + b[(r+h)*n+col+h]
		}
	} }
	strassen_multiply(&x[0], &y[0], mut m7[0], h)
	for r in 0 .. h { for col in 0 .. h {
		i := r * h + col
		unsafe {
			result[r*n+col] = m1[i] + m4[i] - m5[i] + m7[i]
			result[r*n+col+h] = m3[i] + m5[i]
			result[(r+h)*n+col] = m2[i] + m4[i]
			result[(r+h)*n+col+h] = m1[i] - m2[i] + m3[i] + m6[i]
		}
	} }
}

@[export: 'strassen_matrix_multiplication']
pub fn strassen_matrix_multiplication(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	if n_value != 1 && n_value != 2 && n_value != 4 && n_value != 8 { return -1 }
	n := int(n_value)
	cells := n * n
	if length != usize(1 + 2 * cells) { return -1 }
	for i in 0 .. 2 * cells {
		value := unsafe { input[1+i] }
		if value < -2 || value > 2 { return -1 }
	}
	output_bytes := 8 * cells
	if output == nil || capacity < usize(output_bytes) { return -2 }
	mut result := [64]i64{}
	unsafe { strassen_multiply(&input[1], &input[1+cells], mut result[0], n) }
	for i in 0 .. cells {
		bits := u64(result[i])
		for byte in 0 .. 8 {
			unsafe { output[i*8+byte] = u8((bits >> (8*byte)) & 255) }
		}
	}
	return i64(output_bytes)
}
