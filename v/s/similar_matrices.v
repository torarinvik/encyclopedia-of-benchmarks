module similar_matrices

fn det3(m [9]i64) i64 {
	return m[0] * (m[4] * m[8] - m[5] * m[7]) - m[1] * (m[3] * m[8] - m[5] * m[6]) + m[2] * (m[3] * m[7] - m[4] * m[6])
}

fn charpoly(m [9]i64, n int) [3]i64 {
	mut out := [3]i64{}
	mut trace := i64(0)
	for i := 0; i < n; i++ { trace += m[i * n + i] }
	out[0] = -trace
	if n == 2 { out[1] = m[0] * m[3] - m[1] * m[2] }
	if n == 3 {
		out[1] = (m[0] * m[4] - m[1] * m[3]) + (m[0] * m[8] - m[2] * m[6]) + (m[4] * m[8] - m[5] * m[7])
		out[2] = -det3(m)
	}
	return out
}

fn disc3(a i64, b i64, c i64) i64 {
	return a * a * b * b - 4 * b * b * b - 4 * a * a * a * c - 27 * c * c + 18 * a * b * c
}

fn rank_singular(m [9]i64, n int) int {
	for r0 := 0; r0 < n; r0++ {
		for r1 := r0 + 1; r1 < n; r1++ {
			for c0 := 0; c0 < n; c0++ {
				for c1 := c0 + 1; c1 < n; c1++ {
					if m[r0*n+c0] * m[r1*n+c1] - m[r0*n+c1] * m[r1*n+c0] != 0 { return 2 }
				}
			}
		}
	}
	for i := 0; i < n*n; i++ { if m[i] != 0 { return 1 } }
	return 0
}

fn shifted(m [9]i64, n int, numerator i64, denominator i64) [9]i64 {
	mut out := [9]i64{}
	for i := 0; i < n*n; i++ { out[i] = denominator * m[i] }
	for i := 0; i < n; i++ { out[i*n+i] -= numerator }
	return out
}

fn multiply(a [9]i64, b [9]i64, n int) [9]i64 {
	mut out := [9]i64{}
	for row := 0; row < n; row++ {
		for col := 0; col < n; col++ {
			for k := 0; k < n; k++ { out[row*n+col] += a[row*n+k] * b[k*n+col] }
		}
	}
	return out
}

fn similar(a [9]i64, b [9]i64, n int) bool {
	ca := charpoly(a, n)
	cb := charpoly(b, n)
	if ca != cb { return false }
	if n == 1 { return true }
	if n == 2 {
		if ca[0] * ca[0] - 4 * ca[1] != 0 { return true }
		return rank_singular(shifted(a, n, -ca[0], 2), n) == rank_singular(shifted(b, n, -ca[0], 2), n)
	}
	if disc3(ca[0], ca[1], ca[2]) != 0 { return true }
	q := ca[0] * ca[0] - 3 * ca[1]
	if q == 0 {
		da := shifted(a, n, -ca[0], 3)
		db := shifted(b, n, -ca[0], 3)
		if rank_singular(da, n) != rank_singular(db, n) { return false }
		return rank_singular(multiply(da, da, n), n) == rank_singular(multiply(db, db, n), n)
	}
	numerator := 9 * ca[2] - ca[0] * ca[1]
	denominator := 2 * q
	return rank_singular(shifted(a, n, numerator, denominator), n) == rank_singular(shifted(b, n, numerator, denominator), n)
}

@[export: 'similar_matrices']
pub fn similar_matrices(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 19 { return -1 }
	unsafe {
		n_value := input[0]
		if n_value < 1 || n_value > 3 { return -1 }
		n := int(n_value)
		matrix_size := n * n
		if length != usize(1 + 2 * matrix_size) { return -1 }
		mut a := [9]i64{}
		mut b := [9]i64{}
		for i := 0; i < 2 * matrix_size; i++ {
			value := input[1 + i]
			if value < -5 || value > 5 { return -1 }
			if i < matrix_size { a[i] = value } else { b[i - matrix_size] = value }
		}
		return if similar(a, b, n) { i64(1) } else { i64(0) }
	}
}
