package npb_cg_sparse_inverse_power

import "core:c"
import "core:math"

MAX_N :: 32
MAX_OUTER :: 8
MAX_STEPS :: 25
MAX_MICRO :: i64(1_000_000_000)
SCALE :: 1_000_000.0

write_f64_le :: proc(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

matvec :: proc "contextless" (n, nnz: int, v: [^]i64, vector, product: ^[MAX_N]f64) {
	rp := 5
	columns := rp + n + 1
	entries := columns + nnz
	for row := 0; row < n; row += 1 {
		sum := 0.0
		for edge := int(v[rp + row]); edge < int(v[rp + row + 1]); edge += 1 {
			sum += f64(v[entries + edge]) / SCALE * vector^[int(v[columns + edge])]
		}
		product^[row] = sum
	}
}

valid :: proc "contextless" (v: [^]i64, length: c.size_t, n_out, outer_out, steps_out, nnz_out: ^int) -> bool {
	if v == nil || length < 8 do return false
	if v[0] < 1 || v[0] > i64(MAX_N) || v[1] < 1 || v[1] > i64(MAX_OUTER) ||
		v[2] < 1 || v[2] > i64(MAX_STEPS) || v[2] > v[0] ||
		v[3] < -MAX_MICRO || v[3] > MAX_MICRO || v[4] < v[0] || v[4] > i64(6)*v[0] do return false
	n := int(v[0]); outer := int(v[1]); steps := int(v[2]); nnz := int(v[4])
	if length != c.size_t(n + 6 + 2*nnz) do return false
	rp := 5; columns := rp+n+1; entries := columns+nnz
	if v[rp] != 0 || v[rp+n] != i64(nnz) do return false
	for row := 0; row < n; row += 1 {
		begin := v[rp+row]; end := v[rp+row+1]
		if begin < 0 || begin >= end || end > i64(nnz) do return false
		diagonal := i64(0); off_sum := i64(0); previous := i64(-1)
		for edge := int(begin); edge < int(end); edge += 1 {
			column := v[columns+edge]; entry := v[entries+edge]
			if column < 0 || column >= i64(n) || column <= previous || entry == 0 ||
				entry < -MAX_MICRO || entry > MAX_MICRO do return false
			previous = column
			if column == i64(row) do diagonal = entry else do off_sum += if entry < 0 then -entry else entry
		}
		if diagonal <= 0 || diagonal <= off_sum do return false
	}
	for row := 0; row < n; row += 1 {
		for edge := int(v[rp+row]); edge < int(v[rp+row+1]); edge += 1 {
			column := int(v[columns+edge]); found := false
			for reverse := int(v[rp+column]); reverse < int(v[rp+column+1]); reverse += 1 {
				if v[columns+reverse] == i64(row) && v[entries+reverse] == v[entries+edge] { found = true; break }
			}
			if !found do return false
		}
	}
	 n_out^ = n; outer_out^ = outer; steps_out^ = steps; nnz_out^ = nnz
	return true
}

@(export)
npb_cg_sparse_inverse_power :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	n, outer_count, steps, nnz: int
	if !valid(values, length, &n, &outer_count, &steps, &nnz) do return -1
	output_bytes := outer_count * 16
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	x: [MAX_N]f64; z: [MAX_N]f64; r: [MAX_N]f64; p: [MAX_N]f64; q: [MAX_N]f64; az: [MAX_N]f64
	for i := 0; i < n; i += 1 { x[i] = 1.0 }
	for outer := 0; outer < outer_count; outer += 1 {
		rhs2 := 0.0
		for i := 0; i < n; i += 1 { z[i] = 0; r[i] = x[i]; p[i] = x[i]; rhs2 += r[i]*r[i] }
		rr := rhs2
		for step := 0; step < steps && rr > 0; step += 1 {
			matvec(n, nnz, values, &p, &q)
			denom := 0.0
			for i := 0; i < n; i += 1 { denom += p[i]*q[i] }
			if !(denom > 0) || !math.is_finite(denom) do return -1
			alpha := rr/denom
			for i := 0; i < n; i += 1 { z[i] += alpha*p[i]; r[i] -= alpha*q[i] }
			next := 0.0
			for i := 0; i < n; i += 1 { next += r[i]*r[i] }
			if next <= rhs2*1.0e-28 { rr = next; break }
			beta := next/rr
			for i := 0; i < n; i += 1 { p[i] = r[i]+beta*p[i] }
			rr = next
		}
		matvec(n, nnz, values, &z, &az)
		explicit2 := 0.0; dot := 0.0; z2 := 0.0
		for i := 0; i < n; i += 1 { d := x[i]-az[i]; explicit2 += d*d; dot += x[i]*z[i]; z2 += z[i]*z[i] }
		if !(dot > 0) || !(z2 > 0) || !math.is_finite(dot) || !math.is_finite(z2) do return -1
		estimate := f64(values[3])/SCALE + 1.0/dot
		residual_norm := math.sqrt_f64(explicit2)
		if !math.is_finite(estimate) || !math.is_finite(residual_norm) do return -1
		write_f64_le(output, outer*16, estimate)
		write_f64_le(output, outer*16+8, residual_norm)
		z_norm := math.sqrt_f64(z2)
		for i := 0; i < n; i += 1 { x[i] = z[i]/z_norm }
	}
	return i64(output_bytes)
}
