module tsvc_s257_column_coupled_update

const max_n = 8
const max_passes = 4

@[export: 'tsvc_s257_column_coupled_update']
pub fn tsvc_s257_column_coupled_update(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 12 || length > 2 + max_n + 2 * max_n * max_n { return -1 }
	unsafe {
		n_value, passes_value := values[0], values[1]
		if n_value < 2 || n_value > max_n || passes_value < 1 || passes_value > max_passes { return -1 }
		n, passes := int(n_value), int(passes_value)
		if length != usize(2 + n + 2*n*n) { return -1 }
		for index in 2 .. length {
			if values[index] < -1 || values[index] > 1 { return -1 }
		}
		mut a := []i64{len: n}
		mut aa := []i64{len: n*n}
		mut bb := []i64{len: n*n}
		for i in 0 .. n { a[i] = values[2+i] }
		aa_start := 2+n
		bb_start := aa_start+n*n
		for i in 0 .. n*n {
			aa[i] = values[aa_start+i]
			bb[i] = values[bb_start+i]
		}
		for _ in 0 .. passes {
			for i in 1 .. n {
				for j in 0 .. n {
					cell := j*n+i
					a[i] = aa[cell] - a[i-1]
					aa[cell] = a[i] + bb[cell]
				}
			}
		}
		mut checksum := i64(0)
		for i in 0 .. n { checksum += a[i] }
		for i in 0 .. n*n { checksum += aa[i] }
		return checksum
	}
}
