module tsvc_s273_dependent_conditional_update

const max_n = 64
const max_passes = 8

@[export: 'tsvc_s273_dependent_conditional_update']
pub fn tsvc_s273_dependent_conditional_update(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 7 || length > 2 + 5 * max_n { return -1 }
	unsafe {
		n_value, passes_value := values[0], values[1]
		if n_value < 1 || n_value > max_n || passes_value < 1 || passes_value > max_passes { return -1 }
		n, passes := int(n_value), int(passes_value)
		if length != usize(2 + 5*n) { return -1 }
		for index in 2 .. length {
			if values[index] < -2 || values[index] > 2 { return -1 }
		}
		mut a := []i64{len: n}
		mut b := []i64{len: n}
		mut c := []i64{len: n}
		mut d := []i64{len: n}
		mut e := []i64{len: n}
		for i in 0 .. n {
			a[i] = values[2+i]
			b[i] = values[2+n+i]
			c[i] = values[2+2*n+i]
			d[i] = values[2+3*n+i]
			e[i] = values[2+4*n+i]
		}
		for _ in 0 .. passes {
			for i in 0 .. n {
				a[i] += d[i]*e[i]
				if a[i] < 0 { b[i] += d[i]*e[i] }
				c[i] += a[i]*d[i]
			}
		}
		mut checksum := i64(0)
		for i in 0 .. n { checksum += a[i] + b[i] + c[i] }
		return checksum
	}
}
