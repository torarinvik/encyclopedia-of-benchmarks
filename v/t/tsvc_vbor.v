module tsvc_vbor

const max_n = 128

@[export: 'tsvc_vbor']
pub fn tsvc_vbor(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 7 || length > 1 + 6 * max_n { return -1 }
	unsafe {
		n_value := values[0]
		if n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(1 + 6 * n) { return -1 }
		for index in 1 .. length {
			if values[index] < 0 || values[index] > 2 { return -1 }
		}

		mut checksum := i64(0)
		for i in 0 .. n {
			a, b := values[1+i], values[1+n+i]
			c, d := values[1+2*n+i], values[1+3*n+i]
			e, f := values[1+4*n+i], values[1+5*n+i]
			a1 := a*b*c + a*b*d + a*b*e + a*b*f + a*c*d + a*c*e + a*c*f + a*d*e + a*d*f + a*e*f
			b1 := b*c*d + b*c*e + b*c*f + b*d*e + b*d*f + b*e*f
			c1 := c*d*e + c*d*f + c*e*f
			d1 := d*e*f
			checksum += a1*b1*c1*d1
		}
		return checksum
	}
}
