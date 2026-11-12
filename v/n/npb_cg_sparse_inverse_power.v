module npb_cg_sparse_inverse_power

import math

const max_n = 32
const max_outer = 8
const max_steps = 25
const max_micro = i64(1_000_000_000)
const scale = 1_000_000.0

fn write_f64_le(mut output &u8, offset int, value f64) {
	bits := u64(math.bits_from_f64(value))
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

fn matvec(n int, nnz int, values &i64, vector &f64, mut product &f64) {
	rp := 5
	columns := rp + n + 1
	entries := columns + nnz
	unsafe {
		for row in 0 .. n {
			mut sum := 0.0
			for edge in int(values[rp + row]) .. int(values[rp + row + 1]) {
				sum += f64(values[entries + edge]) / scale * vector[int(values[columns + edge])]
			}
			product[row] = sum
		}
	}
}

fn valid(values &i64, length usize) (int, int, int, int, bool) {
	unsafe {
		if values == nil || length < 8 { return 0, 0, 0, 0, false }
		if values[0] < 1 || values[0] > i64(max_n) || values[1] < 1 || values[1] > i64(max_outer) ||
			values[2] < 1 || values[2] > i64(max_steps) || values[2] > values[0] ||
			values[3] < -max_micro || values[3] > max_micro || values[4] < values[0] || values[4] > 6 * values[0] {
			return 0, 0, 0, 0, false
		}
		n := int(values[0]); outer := int(values[1]); steps := int(values[2]); nnz := int(values[4])
		if length != usize(n + 6 + 2 * nnz) { return 0, 0, 0, 0, false }
		rp := 5; columns := rp + n + 1; entries := columns + nnz
		if values[rp] != 0 || values[rp + n] != i64(nnz) { return 0, 0, 0, 0, false }
		for row in 0 .. n {
			begin := values[rp + row]; end := values[rp + row + 1]
			if begin < 0 || begin >= end || end > i64(nnz) { return 0, 0, 0, 0, false }
			mut diagonal := i64(0); mut off_sum := i64(0); mut previous := i64(-1)
			for edge in int(begin) .. int(end) {
				column := values[columns + edge]; entry := values[entries + edge]
				if column < 0 || column >= i64(n) || column <= previous || entry == 0 || entry < -max_micro || entry > max_micro {
					return 0, 0, 0, 0, false
				}
				previous = column
				if column == i64(row) { diagonal = entry } else { off_sum += if entry < 0 { -entry } else { entry } }
			}
			if diagonal <= 0 || diagonal <= off_sum { return 0, 0, 0, 0, false }
		}
		for row in 0 .. n {
			for edge in int(values[rp + row]) .. int(values[rp + row + 1]) {
				column := int(values[columns + edge]); mut found := false
				for reverse in int(values[rp + column]) .. int(values[rp + column + 1]) {
					if values[columns + reverse] == i64(row) && values[entries + reverse] == values[entries + edge] { found = true; break }
				}
				if !found { return 0, 0, 0, 0, false }
			}
		}
		return n, outer, steps, nnz, true
	}
}

@[export: 'npb_cg_sparse_inverse_power']
pub fn npb_cg_sparse_inverse_power(values &i64, length usize, mut output &u8, capacity usize) i64 {
	n, outer_count, steps, nnz, ok := valid(values, length)
	if !ok { return -1 }
	output_bytes := outer_count * 16
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
	mut x := [max_n]f64{}
	mut z := [max_n]f64{}
	mut r := [max_n]f64{}
	mut p := [max_n]f64{}
	mut q := [max_n]f64{}
	mut az := [max_n]f64{}
	unsafe {
		for i in 0 .. n { x[i] = 1.0 }
		for outer in 0 .. outer_count {
			mut rhs2 := 0.0
			for i in 0 .. n { z[i] = 0.0; r[i] = x[i]; p[i] = x[i]; rhs2 += r[i] * r[i] }
			mut rr := rhs2
			for _ in 0 .. steps {
				if rr <= 0.0 { break }
				matvec(n, nnz, values, p.data, q.data)
				mut denominator := 0.0
				for i in 0 .. n { denominator += p[i] * q[i] }
				if !(denominator > 0.0) || !denominator.is_finite() { return -1 }
				alpha := rr / denominator
				for i in 0 .. n { z[i] += alpha * p[i]; r[i] -= alpha * q[i] }
				mut next := 0.0
				for i in 0 .. n { next += r[i] * r[i] }
				if next <= rhs2 * 1.0e-28 { rr = next; break }
				beta := next / rr
				for i in 0 .. n { p[i] = r[i] + beta * p[i] }
				rr = next
			}
			matvec(n, nnz, values, z.data, az.data)
			mut explicit2 := 0.0; mut dot := 0.0; mut z2 := 0.0
			for i in 0 .. n { d := x[i] - az[i]; explicit2 += d * d; dot += x[i] * z[i]; z2 += z[i] * z[i] }
			if !(dot > 0.0) || !(z2 > 0.0) || !dot.is_finite() || !z2.is_finite() { return -1 }
			estimate := f64(values[3]) / scale + 1.0 / dot
			residual_norm := math.sqrt(explicit2)
			if !estimate.is_finite() || !residual_norm.is_finite() { return -1 }
			write_f64_le(mut output, outer * 16, estimate)
			write_f64_le(mut output, outer * 16 + 8, residual_norm)
			z_norm := math.sqrt(z2)
			for i in 0 .. n { x[i] = z[i] / z_norm }
		}
	}
	return i64(output_bytes)
}
