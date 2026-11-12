module npb_lu_block_ssor

import math

const max_points = 32
const max_micro = i64(1_000_000_000)
const scale = 1_000_000.0

fn write_f64_le(mut output &u8, offset int, value f64) {
	bits := u64(math.bits_from_f64(value))
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

fn solve5(d &f64, rhs &f64, mut result &f64) bool {
	mut a := [25]f64{}
	mut b := [5]f64{}
	unsafe {
		for i in 0 .. 25 { a[i] = d[i] }
		for i in 0 .. 5 { b[i] = rhs[i] }
		for pivot in 0 .. 5 {
			divisor := a[pivot * 5 + pivot]
			if !(divisor > 0.0) || !divisor.is_finite() { return false }
			for row in pivot + 1 .. 5 {
				factor := a[row * 5 + pivot] / divisor
				for column in pivot + 1 .. 5 { a[row * 5 + column] -= factor * a[pivot * 5 + column] }
				b[row] -= factor * b[pivot]
			}
		}
		for back in 0 .. 5 {
			row := 4 - back
			mut tail := 0.0
			for column in row + 1 .. 5 { tail += a[row * 5 + column] * result[column] }
			result[row] = (b[row] - tail) / a[row * 5 + row]
		}
	}
	return true
}

fn apply_operator(nx int, ny int, nz int, d &f64, c &f64, x &f64, mut out &f64) {
	points := nx * ny * nz
	nxy := nx * ny
	unsafe {
		for point in 0 .. points {
			ix := point % nx
			iy := (point / nx) % ny
			iz := point / nxy
			for row in 0 .. 5 {
				mut total := 0.0
				for column in 0 .. 5 { total += d[row * 5 + column] * x[point * 5 + column] }
				if ix > 0 { total += c[0] * x[(point - 1) * 5 + row] }
				if ix + 1 < nx { total += c[0] * x[(point + 1) * 5 + row] }
				if iy > 0 { total += c[1] * x[(point - nx) * 5 + row] }
				if iy + 1 < ny { total += c[1] * x[(point + nx) * 5 + row] }
				if iz > 0 { total += c[2] * x[(point - nxy) * 5 + row] }
				if iz + 1 < nz { total += c[2] * x[(point + nxy) * 5 + row] }
				out[point * 5 + row] = total
			}
		}
	}
}

fn valid(values &i64, length usize) (int, int, int, int, bool) {
	unsafe {
		if values == nil || length < 42 || length > 352 { return 0, 0, 0, 0, false }
		if values[0] < 1 || values[0] > 4 || values[1] < 1 || values[1] > 4 || values[2] < 1 || values[2] > 4 || values[3] < 1 || values[3] > 8 { return 0, 0, 0, 0, false }
		nx := int(values[0]); ny := int(values[1]); nz := int(values[2]); sweeps := int(values[3])
		points := nx * ny * nz
		if points > max_points || length != usize(32 + 10 * points) { return 0, 0, 0, 0, false }
		for i in 4 .. int(length) { if values[i] < -max_micro || values[i] > max_micro { return 0, 0, 0, 0, false } }
		for row in 0 .. 5 {
			diagonal := values[4 + row * 5 + row]
			mut off_sum := i64(0)
			for column in 0 .. 5 {
				entry := values[4 + row * 5 + column]
				if entry != values[4 + column * 5 + row] { return 0, 0, 0, 0, false }
				if column != row { off_sum += if entry < 0 { -entry } else { entry } }
			}
			if nx > 1 { off_sum += 2 * (if values[29] < 0 { -values[29] } else { values[29] }) }
			if ny > 1 { off_sum += 2 * (if values[30] < 0 { -values[30] } else { values[30] }) }
			if nz > 1 { off_sum += 2 * (if values[31] < 0 { -values[31] } else { values[31] }) }
			if diagonal <= 0 || diagonal <= off_sum { return 0, 0, 0, 0, false }
		}
		return nx, ny, nz, sweeps, true
	}
}

@[export: 'npb_lu_block_ssor']
pub fn npb_lu_block_ssor(values &i64, length usize, mut output &u8, capacity usize) i64 {
	nx, ny, nz, sweeps, ok := valid(values, length)
	if !ok { return -1 }
	points := nx * ny * nz
	count := points * 5
	output_bytes := 8 * (sweeps + count)
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
	mut d := [25]f64{}
	mut c := [3]f64{}
	mut x := [max_points * 5]f64{}
	mut rhs := [max_points * 5]f64{}
	mut applied := [max_points * 5]f64{}
	mut residual := [max_points * 5]f64{}
	mut forward := [max_points * 5]f64{}
	mut correction := [max_points * 5]f64{}
	unsafe {
		for i in 0 .. 25 { d[i] = f64(values[4 + i]) / scale }
		for axis in 0 .. 3 { c[axis] = f64(values[29 + axis]) / scale }
		for i in 0 .. count { rhs[i] = f64(values[32 + i]) / scale; x[i] = f64(values[32 + count + i]) / scale }
	}
	nxy := nx * ny
	for sweep in 0 .. sweeps {
		apply_operator(nx, ny, nz, d.data, c.data, x.data, applied.data)
		for i in 0 .. count { residual[i] = rhs[i] - applied[i] }
		for point in 0 .. points {
			ix := point % nx; iy := (point / nx) % ny; iz := point / nxy
			mut local := [5]f64{}; mut solved := [5]f64{}
			for row in 0 .. 5 { local[row] = residual[point * 5 + row] }
			if ix > 0 { for row in 0 .. 5 { local[row] -= c[0] * forward[(point - 1) * 5 + row] } }
			if iy > 0 { for row in 0 .. 5 { local[row] -= c[1] * forward[(point - nx) * 5 + row] } }
			if iz > 0 { for row in 0 .. 5 { local[row] -= c[2] * forward[(point - nxy) * 5 + row] } }
			if !solve5(d.data, local.data, mut solved.data) { return -1 }
			for row in 0 .. 5 { forward[point * 5 + row] = solved[row] }
		}
		for back in 0 .. points {
			point := points - 1 - back; ix := point % nx; iy := (point / nx) % ny; iz := point / nxy
			mut local := [5]f64{}; mut solved := [5]f64{}
			for row in 0 .. 5 { for column in 0 .. 5 { local[row] += d[row * 5 + column] * forward[point * 5 + column] } }
			if ix + 1 < nx { for row in 0 .. 5 { local[row] -= c[0] * correction[(point + 1) * 5 + row] } }
			if iy + 1 < ny { for row in 0 .. 5 { local[row] -= c[1] * correction[(point + nx) * 5 + row] } }
			if iz + 1 < nz { for row in 0 .. 5 { local[row] -= c[2] * correction[(point + nxy) * 5 + row] } }
			if !solve5(d.data, local.data, mut solved.data) { return -1 }
			for row in 0 .. 5 { correction[point * 5 + row] = solved[row] }
		}
		for i in 0 .. count { x[i] += correction[i] }
		apply_operator(nx, ny, nz, d.data, c.data, x.data, applied.data)
		mut norm2 := 0.0
		for i in 0 .. count { difference := rhs[i] - applied[i]; norm2 += difference * difference }
		write_f64_le(mut output, sweep * 8, math.sqrt(norm2))
	}
	for i in 0 .. count { write_f64_le(mut output, (sweeps + i) * 8, x[i]) }
	return i64(output_bytes)
}
