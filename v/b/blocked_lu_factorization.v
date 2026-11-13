@[noinline]
fn blocked_lu_mul(a f64, b f64) f64 { return a * b }
@[noinline]
fn blocked_lu_add(a f64, b f64) f64 { return a + b }

fn blocked_lu_exact_integer(x f64, lo i64, hi i64) bool {
	if !x.is_finite() || x < f64(lo) || x > f64(hi) { return false }
	return f64(i64(x)) == x
}

@[export: 'blocked_lu_factorization']
pub fn blocked_lu_factorization(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 66 { return -1 }
		if !blocked_lu_exact_integer(input[0], 2, 8) { return -1 }
		n := int(input[0])
		if n % 2 != 0 || input_length != usize(1+n*n) { return -1 }
		mut schur := [64]f64{}
		for row in 0 .. n {
			mut off_sum := i64(0)
			for col in 0 .. n {
				p := row*n+col
				lo := i64(-2); hi := i64(2)
				if row == col { lo = 1; hi = 16 }
				if !blocked_lu_exact_integer(input[p+1], lo, hi) { return -1 }
				value := i64(input[p+1])
				schur[p] = f64(value)
				if row != col { off_sum += if value < 0 { -value } else { value } }
			}
			if schur[row*n+row] <= f64(off_sum) { return -1 }
		}
		mut lower := [64]f64{}
		mut upper := [64]f64{}
		for k := 0; k < n; k += 2 {
			u00 := schur[k*n+k]; u01 := schur[k*n+k+1]
			if u00 == 0 || !u00.is_finite() { return -1 }
			l10 := schur[(k+1)*n+k] / u00
			u11 := schur[(k+1)*n+k+1] - l10*u01
			if !l10.is_finite() || !u11.is_finite() || u11 == 0 { return -1 }
			lower[k*n+k] = 1; lower[(k+1)*n+k] = l10; lower[(k+1)*n+k+1] = 1
			upper[k*n+k] = u00; upper[k*n+k+1] = u01; upper[(k+1)*n+k+1] = u11
			for j := k+2; j < n; j += 2 {
				for col := j; col < j+2; col += 1 {
					s0 := schur[k*n+col]; s1 := schur[(k+1)*n+col]
					upper[k*n+col] = s0
					upper[(k+1)*n+col] = s1-l10*s0
				}
			}
			for i := k+2; i < n; i += 2 {
				for row := i; row < i+2; row += 1 {
					s0 := schur[row*n+k]; s1 := schur[row*n+k+1]
					l0 := s0/u00; l1 := (s1-l0*u01)/u11
					lower[row*n+k] = l0; lower[row*n+k+1] = l1
				}
			}
			for i := k+2; i < n; i += 2 {
				for j := k+2; j < n; j += 2 {
					for row := i; row < i+2; row += 1 {
						for col := j; col < j+2; col += 1 {
							update := lower[row*n+k]*upper[k*n+col] + lower[row*n+k+1]*upper[(k+1)*n+col]
							schur[row*n+col] -= update
						}
					}
				}
			}
		}
		mut staged := [128]f64{}
		m := n*n
		for row in 0 .. n {
			lower[row*n+row] = 1
			for col in row .. n { upper[row*n+col] = schur[row*n+col] }
		}
		for i in 0 .. m {
			if !lower[i].is_finite() || !upper[i].is_finite() { return -1 }
			staged[i] = lower[i]; staged[m+i] = upper[i]
		}
		length := 2*m
		if output == nil || capacity < usize(length) { return -2 }
		for i in 0 .. length { output[i] = staged[i] }
		return i64(length)
	}
}
