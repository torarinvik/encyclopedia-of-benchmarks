module hpcg_profile

import math

const max_n = 32
const max_coarse = 16
const max_steps = 12
const max_micro = i64(1_000_000_000)
const scale = 1_000_000.0

fn write_f64_le(mut output &u8, offset int, value f64) {
	bits := u64(math.bits_from_f64(value))
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

fn matvec(values &i64, n int, nnz int, vector &f64, mut product &f64) {
	col := 4 + n
	val := col + nnz
	unsafe {
		for row in 0 .. n {
			mut sum := 0.0
			for edge in int(values[3 + row]) .. int(values[4 + row]) {
				sum += f64(values[val + edge]) / scale * vector[int(values[col + edge])]
			}
			product[row] = sum
		}
	}
}

fn coarse_solve(values &i64, n int, nnz int, rhs &f64, mut result &f64) bool {
	cn := (n + 1) / 2
	col := 4 + n
	val := col + nnz
	mut a := [max_coarse * max_coarse]f64{}
	mut lower := [max_coarse * max_coarse]f64{}
	unsafe {
		for row in 0 .. n {
			for edge in int(values[3 + row]) .. int(values[4 + row]) {
				index := (row / 2) * max_coarse + int(values[col + edge]) / 2
				a[index] += f64(values[val + edge]) / scale
			}
		}
		for i in 0 .. cn {
			for j in 0 .. i + 1 {
				mut value := a[i * max_coarse + j]
				for k in 0 .. j { value -= lower[i * max_coarse + k] * lower[j * max_coarse + k] }
				if i == j {
					if value <= 0.0 { return false }
					lower[i * max_coarse + j] = math.sqrt(value)
				} else { lower[i * max_coarse + j] = value / lower[j * max_coarse + j] }
			}
		}
		mut y := [max_coarse]f64{}
		for i in 0 .. cn {
			mut value := rhs[i]
			for j in 0 .. i { value -= lower[i * max_coarse + j] * y[j] }
			y[i] = value / lower[i * max_coarse + i]
		}
		for ii := cn - 1; ii >= 0; ii-- {
			mut value := y[ii]
			for j in ii + 1 .. cn { value -= lower[j * max_coarse + ii] * result[j] }
			result[ii] = value / lower[ii * max_coarse + ii]
		}
	}
	return true
}

fn precondition(values &i64, n int, nnz int, diagonal &f64, residual &f64, mut result &f64) bool {
	col := 4 + n
	val := col + nnz
	mut pre := [max_n]f64{}
	mut product := [max_n]f64{}
	mut middle := [max_n]f64{}
	mut post_r := [max_n]f64{}
	mut post := [max_n]f64{}
	mut coarse_rhs := [max_coarse]f64{}
	mut coarse_x := [max_coarse]f64{}
	unsafe {
		for row in 0 .. n {
			mut value := residual[row]
			for edge in int(values[3 + row]) .. int(values[4 + row]) {
				c := int(values[col + edge])
				if c < row { value -= f64(values[val + edge]) / scale * pre[c] }
			}
			pre[row] = value / diagonal[row]
		}
		matvec(values, n, nnz, pre.data, product.data)
		for row in 0 .. n { coarse_rhs[row / 2] += residual[row] - product[row] }
		if !coarse_solve(values, n, nnz, coarse_rhs.data, coarse_x.data) { return false }
		for row in 0 .. n { middle[row] = pre[row] + coarse_x[row / 2] }
		matvec(values, n, nnz, middle.data, product.data)
		for row in 0 .. n { post_r[row] = residual[row] - product[row] }
		for ii := n - 1; ii >= 0; ii-- {
			mut value := post_r[ii]
			for edge in int(values[3 + ii]) .. int(values[4 + ii]) {
				c := int(values[col + edge])
				if c > ii { value -= f64(values[val + edge]) / scale * post[c] }
			}
			post[ii] = value / diagonal[ii]
		}
		for row in 0 .. n { result[row] = middle[row] + post[row] }
	}
	return true
}

fn valid(values &i64, length usize, mut diagonal &f64) (int, int, int, bool) {
	unsafe {
		if values == nil || length < 8 || length > 452 { return 0, 0, 0, false }
		if values[0] < 1 || values[0] > i64(max_n) || values[1] < 1 || values[1] > i64(max_steps) ||
			values[1] > values[0] || values[2] < values[0] || values[2] > 6 * values[0] { return 0, 0, 0, false }
		n := int(values[0]); steps := int(values[1]); nnz := int(values[2])
		if length != usize(4 + 2*n + 2*nnz) { return 0, 0, 0, false }
		col := 4 + n; val := col + nnz; rhs := val + nnz
		if values[3] != 0 || values[3+n] != i64(nnz) { return 0, 0, 0, false }
		for row in 0 .. n {
			begin := values[3+row]; end := values[4+row]
			if begin < 0 || begin >= end || end > i64(nnz) || end-begin > 6 { return 0, 0, 0, false }
			mut d := i64(0); mut off := i64(0); mut previous := i64(-1)
			for edge in int(begin) .. int(end) {
				c := values[col+edge]; a := values[val+edge]
				if c < 0 || c >= i64(n) || c <= previous || a == 0 || a < -max_micro || a > max_micro { return 0, 0, 0, false }
				previous = c
				if c == i64(row) { d = a } else { off += if a < 0 { -a } else { a } }
			}
			if d <= 0 || d <= off || values[rhs+row] < -max_micro || values[rhs+row] > max_micro { return 0, 0, 0, false }
			diagonal[row] = f64(d) / scale
		}
		for row in 0 .. n {
			for edge in int(values[3+row]) .. int(values[4+row]) {
				c := int(values[col+edge]); mut found := false
				for reverse in int(values[3+c]) .. int(values[4+c]) {
					if values[col+reverse] == i64(row) && values[val+reverse] == values[val+edge] { found = true; break }
				}
				if !found { return 0, 0, 0, false }
			}
		}
		return n, steps, nnz, true
	}
}

@[export: 'hpcg_profile']
pub fn hpcg_profile(values &i64, length usize, mut output &u8, capacity usize) i64 {
	mut diagonal := [max_n]f64{}
	n, steps, nnz, ok := valid(values, length, diagonal.data)
	if !ok { return -1 }
	output_bytes := 8 * (n + 1)
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
	rhs := 4 + n + 2 * nnz
	mut b := [max_n]f64{}; mut x := [max_n]f64{}; mut r := [max_n]f64{}
	mut z := [max_n]f64{}; mut p := [max_n]f64{}; mut q := [max_n]f64{}; mut ax := [max_n]f64{}
	unsafe {
		mut b2 := 0.0
		for i in 0 .. n { b[i] = f64(values[rhs+i]) / scale; r[i] = b[i]; b2 += b[i] * b[i] }
		if b2 > 0.0 {
			if !precondition(values,n,nnz,diagonal.data,r.data,z.data) { return -1 }
			for i in 0 .. n { p[i] = z[i] }
			mut rho := 0.0; for i in 0 .. n { rho += r[i] * z[i] }
			if rho <= 0.0 { return -1 }
			for _ in 0 .. steps {
				matvec(values,n,nnz,p.data,q.data)
				mut curvature := 0.0; for i in 0 .. n { curvature += p[i] * q[i] }
				if curvature <= 0.0 { return -1 }
				alpha := rho / curvature
				for i in 0 .. n { x[i] += alpha*p[i]; r[i] -= alpha*q[i] }
				mut r2 := 0.0; for i in 0 .. n { r2 += r[i]*r[i] }
				if r2 <= b2 * 1.0e-28 { break }
				mut next_z := [max_n]f64{}
				if !precondition(values,n,nnz,diagonal.data,r.data,next_z.data) { return -1 }
				mut next_rho := 0.0; for i in 0 .. n { next_rho += r[i]*next_z[i] }
				if next_rho <= 0.0 { return -1 }
				beta := next_rho / rho
				for i in 0 .. n { z[i] = next_z[i]; p[i] = z[i]+beta*p[i] }
				rho = next_rho
			}
		}
		matvec(values,n,nnz,x.data,ax.data)
		mut residual2 := 0.0
		for i in 0 .. n { e := b[i]-ax[i]; residual2 += e*e; write_f64_le(mut output,8*i,x[i]) }
		write_f64_le(mut output,8*n,math.sqrt(residual2))
	}
	return i64(output_bytes)
}
