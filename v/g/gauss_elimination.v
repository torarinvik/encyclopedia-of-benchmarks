module gauss_elimination

import math

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.f64_bits(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'gauss_elimination']
pub fn gauss_elimination(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > 8 { return -1 }
		n := int(input[0])
		if length != usize(1+n*n+n) { return -1 }
		for i in 1 .. int(length) { if input[i] < -100 || input[i] > 100 { return -1 } }
		mut m := []f32{len: 72}
		for r in 0 .. n { for c in 0 .. n { m[r*9+c]=f32(input[1+r*n+c]) }; m[r*9+n]=f32(input[1+n*n+r]) }
		for i in 0 .. n-1 {
			mut pivot := i
			for j in i .. n { if math.abs(m[j*9+i]) > math.abs(m[pivot*9+i]) { pivot=j } }
			if m[pivot*9+i] == 0 { return -1 }
			if pivot != i { for l in 0 .. n+1 { t:=m[i*9+l]; m[i*9+l]=m[pivot*9+l]; m[pivot*9+l]=t } }
			for j in i+1 .. n {
				tmp := -(m[j*9+i]/m[i*9+i])
				for l in 0 .. n+1 { m[j*9+l]=m[j*9+l]+m[i*9+l]*tmp }
			}
		}
		if m[(n-1)*9+n-1] == 0 { return -1 }
		if output == nil || capacity < usize(n*8) { return -2 }
		mut ans := []f32{len: 8}
		for k in 0 .. n { row:=n-1-k; mut mul:=f32(0); for q in 0 .. n-row-1 { l:=n-1-q; mul=mul+m[row*9+l]*ans[l] }; ans[row]=(m[row*9+n]-mul)/m[row*9+row] }
		for i in 0 .. n { put_f64_le(mut output, i*8, math.round_to_even(f64(ans[i])*100)/100) }
		return i64(n*8)
	}
}
