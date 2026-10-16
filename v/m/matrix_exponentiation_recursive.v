module matrix_exponentiation_recursive

fn multiply(a [4]i64, b [4]i64) [4]i64 {
	mut c := [4]i64{}
	for r in 0 .. 2 { for col in 0 .. 2 { for k in 0 .. 2 { c[r*2+col] += a[r*2+k] * b[k*2+col] } } }
	return c
}
fn power(a [4]i64, e i64) [4]i64 {
	if e == 0 { return [i64(1), 0, 0, 1] }
	if e % 2 == 1 { return multiply(power(a, e-1), a) }
	half := power(a, e/2)
	return multiply(half, half)
}
fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8((bits >> (8*b)) & 255) } }
}
@[export: 'matrix_exponentiation_recursive']
pub fn matrix_exponentiation_recursive(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length != 5 { return -2 }
	unsafe {
		if input[0] < 0 || input[0] > 30 { return -2 }
		for i in 1 .. 5 { if input[i] < -1 || input[i] > 1 { return -2 } }
		if output == nil || output_capacity < 32 { return -3 }
		result := power([input[1], input[2], input[3], input[4]], input[0])
		for i in 0 .. 4 { store_i64_le(mut output, i*8, result[i]) }
		return 4
	}
}
