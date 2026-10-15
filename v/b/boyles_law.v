module boyles_law

fn rounded_milli(numerator i64, denominator i64) i64 {
	scaled := numerator * 1000
	mut quotient := scaled / denominator
	remainder := scaled % denominator
	if 2 * remainder > denominator || (2 * remainder == denominator && quotient % 2 != 0) {
		quotient += 1
	}
	return quotient
}

@[export: 'boyles_law']
pub fn boyles_law(values &i64, length usize) f64 {
	if length != 4 { return -1.0e300 }
	target := unsafe { values[0] }
	a := unsafe { values[1] }
	b := unsafe { values[2] }
	c_value := unsafe { values[3] }
	if target < 0 || target > 3 || a < 1 || a > 1000 || b < 1 || b > 1000 || c_value < 1 || c_value > 1000 {
		return -1.0e300
	}
	mut numerator := i64(0)
	mut denominator := i64(1)
	if target == 0 {
		numerator = c_value * a
		denominator = b
	} else if target == 1 {
		numerator = b * a
		denominator = c_value
	} else if target == 2 {
		numerator = c_value * b
		denominator = a
	} else {
		numerator = c_value * a
		denominator = b
	}
	return f64(rounded_milli(numerator, denominator)) / 1000.0
}
