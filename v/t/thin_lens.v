module thin_lens

@[export: 'thin_lens']
pub fn thin_lens(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	unsafe {
		if values == nil { return -1.0e300 }
		operation := values[0]
		a := values[1]
		b := values[2]
		if a < -1000 || a > 1000 || b < -1000 || b > 1000 { return -1.0e300 }
		if operation == 0 {
			if a == 0 || b == 0 || a == b { return -1.0e300 }
			f := f64(a)
			u := f64(b)
			return 1.0 / ((1.0 / f) - (1.0 / u))
		}
		if operation == 1 {
			if b == 0 { return -1.0e300 }
			return f64(a) / f64(b)
		}
		if operation == 2 {
			if b != 0 { return -1.0e300 }
			return if a > 0 { 1.0 } else { 0.0 }
		}
		return -1.0e300
	}
}
