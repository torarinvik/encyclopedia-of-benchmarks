package hpcg_profile

import "core:c"
import "core:math"

MAX_N :: 32
MAX_COARSE :: 16
MAX_STEPS :: 12
MAX_MICRO :: i64(1_000_000_000)
SCALE :: 1_000_000.0

write_f64_le :: proc(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

valid :: proc "contextless" (v: [^]i64, length: c.size_t, n_out, steps_out, nnz_out: ^int,
								 diagonal: ^[MAX_N]f64) -> bool {
	if v == nil || length < 8 || length > 452 do return false
	if v[0] < 1 || v[0] > i64(MAX_N) || v[1] < 1 || v[1] > i64(MAX_STEPS) ||
		v[1] > v[0] || v[2] < v[0] || v[2] > 6*v[0] do return false
	n := int(v[0]); steps := int(v[1]); nnz := int(v[2])
	if length != c.size_t(4 + 2*n + 2*nnz) do return false
	rp := 3; col := 4+n; val := col+nnz; rhs := val+nnz
	if v[rp] != 0 || v[rp+n] != i64(nnz) do return false
	for row := 0; row < n; row += 1 {
		begin := v[rp+row]; end := v[rp+row+1]
		if begin < 0 || begin >= end || end > i64(nnz) || end-begin > 6 do return false
		diag := i64(0); off := i64(0); previous := i64(-1)
		for edge := int(begin); edge < int(end); edge += 1 {
			cidx := v[col+edge]; a := v[val+edge]
			if cidx < 0 || cidx >= i64(n) || cidx <= previous || a == 0 || a < -MAX_MICRO || a > MAX_MICRO do return false
			previous = cidx
			if cidx == i64(row) do diag = a else do off += if a < 0 then -a else a
		}
		if diag <= 0 || diag <= off || v[rhs+row] < -MAX_MICRO || v[rhs+row] > MAX_MICRO do return false
		diagonal^[row] = f64(diag) / SCALE
	}
	for row := 0; row < n; row += 1 {
		for edge := int(v[rp+row]); edge < int(v[rp+row+1]); edge += 1 {
			cidx := int(v[col+edge]); found := false
			for rev := int(v[rp+cidx]); rev < int(v[rp+cidx+1]); rev += 1 {
				if v[col+rev] == i64(row) && v[val+rev] == v[val+edge] { found = true; break }
			}
			if !found do return false
		}
	}
	 n_out^ = n; steps_out^ = steps; nnz_out^ = nnz
	return true
}

matvec :: proc "contextless" (v: [^]i64, n, nnz: int, x, y: ^[MAX_N]f64) {
	col := 4+n; val := col+nnz
	for row := 0; row < n; row += 1 {
		sum := 0.0
		for edge := int(v[3+row]); edge < int(v[4+row]); edge += 1 {
			sum += f64(v[val+edge]) / SCALE * x^[int(v[col+edge])]
		}
		y^[row] = sum
	}
}

coarse_solve :: proc "contextless" (v: [^]i64, n, nnz: int, rhs: ^[MAX_COARSE]f64,
									 result: ^[MAX_COARSE]f64) -> bool {
	cn := (n+1)/2; col := 4+n; val := col+nnz
	 a: [MAX_COARSE][MAX_COARSE]f64 = {}; l: [MAX_COARSE][MAX_COARSE]f64 = {}
	for row := 0; row < n; row += 1 {
		for edge := int(v[3+row]); edge < int(v[4+row]); edge += 1 {
			a[row/2][int(v[col+edge])/2] += f64(v[val+edge]) / SCALE
		}
	}
	for i := 0; i < cn; i += 1 {
		for j := 0; j <= i; j += 1 {
			value := a[i][j]
			for k := 0; k < j; k += 1 { value -= l[i][k]*l[j][k] }
			if i == j { if value <= 0 do return false; l[i][j] = math.sqrt(value) }
			else { l[i][j] = value/l[j][j] }
		}
	}
	var y: [MAX_COARSE]f64
	for i := 0; i < cn; i += 1 { value := rhs^[i]; for j := 0; j < i; j += 1 { value -= l[i][j]*y[j] }; y[i] = value/l[i][i] }
	for ii := cn-1; ii >= 0; ii -= 1 { value := y[ii]; for j := ii+1; j < cn; j += 1 { value -= l[j][ii]*result^[j] }; result^[ii] = value/l[ii][ii] }
	return true
}

precondition :: proc "contextless" (v: [^]i64, n, nnz: int, diagonal: ^[MAX_N]f64,
								 r: ^[MAX_N]f64, z: ^[MAX_N]f64) -> bool {
	col := 4+n; val := col+nnz
	var pre, product, middle, post_r, post: [MAX_N]f64
	var coarse_rhs, coarse_x: [MAX_COARSE]f64
	for row := 0; row < n; row += 1 {
		value := r^[row]
		for edge := int(v[3+row]); edge < int(v[4+row]); edge += 1 { cidx := int(v[col+edge]); if cidx < row { value -= f64(v[val+edge])/SCALE*pre[cidx] } }
		pre[row] = value/diagonal^[row]
	}
	matvec(v,n,nnz,&pre,&product)
	for row := 0; row < n; row += 1 { coarse_rhs[row/2] += r^[row]-product[row] }
	if !coarse_solve(v,n,nnz,&coarse_rhs,&coarse_x) do return false
	for row := 0; row < n; row += 1 { middle[row] = pre[row]+coarse_x[row/2] }
	matvec(v,n,nnz,&middle,&product)
	for row := 0; row < n; row += 1 { post_r[row] = r^[row]-product[row] }
	for ii := n-1; ii >= 0; ii -= 1 {
		value := post_r[ii]
		for edge := int(v[3+ii]); edge < int(v[4+ii]); edge += 1 { cidx := int(v[col+edge]); if cidx > ii { value -= f64(v[val+edge])/SCALE*post[cidx] } }
		post[ii] = value/diagonal^[ii]
	}
	for row := 0; row < n; row += 1 { z^[row] = middle[row]+post[row] }
	return true
}

@(export)
hpcg_profile :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	n, steps, nnz: int
	var diagonal: [MAX_N]f64
	if !valid(values,length,&n,&steps,&nnz,&diagonal) do return -1
	bytes := 8*(n+1)
	if output == nil || capacity < c.size_t(bytes) do return -2
	rhs := 4+n+2*nnz
	var b,x,r,z,p,q,ax: [MAX_N]f64
	b2 := 0.0
	for i := 0; i < n; i += 1 { b[i]=f64(values[rhs+i])/SCALE; r[i]=b[i]; b2 += b[i]*b[i] }
	if b2 > 0 {
		if !precondition(values,n,nnz,&diagonal,&r,&z) do return -1
		for i := 0; i < n; i += 1 { p[i]=z[i] }
		rho := 0.0; for i := 0; i < n; i += 1 { rho += r[i]*z[i] }
		if rho <= 0 do return -1
		for step := 0; step < steps; step += 1 {
			matvec(values,n,nnz,&p,&q)
			curvature := 0.0; for i := 0; i < n; i += 1 { curvature += p[i]*q[i] }
			if curvature <= 0 do return -1
			alpha := rho/curvature
			for i := 0; i < n; i += 1 { x[i] += alpha*p[i]; r[i] -= alpha*q[i] }
		r2 := 0.0; for i := 0; i < n; i += 1 { r2 += r[i]*r[i] }
			if r2 <= b2*1.0e-28 do break
			var next_z: [MAX_N]f64
			if !precondition(values,n,nnz,&diagonal,&r,&next_z) do return -1
			next_rho := 0.0; for i := 0; i < n; i += 1 { next_rho += r[i]*next_z[i] }
			if next_rho <= 0 do return -1
			beta := next_rho/rho
			for i := 0; i < n; i += 1 { z[i]=next_z[i]; p[i]=z[i]+beta*p[i] }
			rho = next_rho
		}
	}
	matvec(values,n,nnz,&x,&ax)
	r2 := 0.0
	for i := 0; i < n; i += 1 { e := b[i]-ax[i]; r2 += e*e; write_f64_le(output,8*i,x[i]) }
	write_f64_le(output,8*n,math.sqrt(r2))
	return i64(bytes)
}
