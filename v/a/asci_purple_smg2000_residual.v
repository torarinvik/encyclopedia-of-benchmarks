// Clean-room bounded residual profile; see package README and RIGHTS.md.
import math

@[export: 'asci_purple_smg2000_residual']
pub fn asci_purple_smg2000_residual(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length < 19 || length > 253 { return -1 }
		for q in 0 .. 3 {
			v := input[q]
			if !v.is_finite() || math.trunc(v) != v || v < 2 || v > 5 { return -1 }
		}
		nx, ny, nz := int(input[0]), int(input[1]), int(input[2])
		cells := nx * ny * nz
		if length != usize(3 + 2 * cells) { return -1 }
		for q in 3 .. length {
			v := input[q]
			if !v.is_finite() || math.trunc(v) != v || v < -1000 || v > 1000 { return -1 }
		}
		if output == nil || capacity < usize(cells) { return -2 }
		si, sj := ny * nz, nz
		for i in 0 .. nx { for j in 0 .. ny { for k in 0 .. nz {
			q := i * si + j * sj + k
			x := i64(input[3 + q])
			mut ax := i64(222) * x
			if i > 0 { ax -= i64(input[3 + q - si]) }
			if i + 1 < nx { ax -= i64(input[3 + q + si]) }
			if j > 0 { ax -= i64(10) * i64(input[3 + q - sj]) }
			if j + 1 < ny { ax -= i64(10) * i64(input[3 + q + sj]) }
			if k > 0 { ax -= i64(100) * i64(input[3 + q - 1]) }
			if k + 1 < nz { ax -= i64(100) * i64(input[3 + q + 1]) }
			b := i64(input[3 + cells + q])
			output[q] = f64(10 * b - ax) / 10.0
		} } }
		return i64(cells)
	}
}
