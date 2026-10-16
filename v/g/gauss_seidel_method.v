module gauss_seidel_method

import math

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.f64_bits(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'gauss_seidel_method']
pub fn gauss_seidel_method(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 8 { return -1 }
		n := int(input[0])
		if length != usize(1+n*n+n) { return -1 }
		rhs := 1+n*n
		for k in 1 .. int(length) { if input[k] < -1_000_000_000 || input[k] > 1_000_000_000 { return -1 } }
		for row in 0 .. n {
			diagonal := input[1+row*n+row]
			if diagonal <= 0 { return -1 }
			mut off_sum := i64(0)
			for col in 0 .. n {
				value := input[1+row*n+col]
				if value != input[1+col*n+row] { return -1 }
				if row != col { off_sum += if value < 0 { -value } else { value } }
			}
			if diagonal <= off_sum { return -1 }
		}
		if output == nil || capacity < usize(n*8) { return -2 }
		mut a := []f64{len: 64}
		mut b := []f64{len: 8}
		mut x := []f64{len: 8}
		mut old := []f64{len: 8}
		for i in 0 .. n*n { a[i] = f64(input[i+1])/1_000_000.0 }
		for i in 0 .. n { b[i] = f64(input[rhs+i])/1_000_000.0 }
		for _ in 0 .. 1000 {
			for i in 0 .. n { old[i] = x[i] }
			for i in 0 .. n {
				mut before := 0.0
				mut after := 0.0
				for j in 0 .. i { before += a[i*n+j]*x[j] }
				for j in i+1 .. n { after += a[i*n+j]*old[j] }
				x[i] = (b[i]-before-after)/a[i*n+i]
			}
			mut done := true
			for i in 0 .. n { if math.abs(x[i]-old[i]) >= 1.0e-10 { done = false } }
			if done { break }
		}
		for i in 0 .. n { put_f64_le(mut output, i*8, math.round(x[i]*1.0e10)/1.0e10) }
		return i64(n*8)
	}
}
