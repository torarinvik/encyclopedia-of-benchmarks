module ideal_gas_law

// Solve one ideal-gas-law variable using a portable operation selector.
@[export: 'ideal_gas_law']
pub fn ideal_gas_law(values &i64, length usize) f64 {
	if length != 4 { return -1.0e300 }
	operation := unsafe { values[0] }
	a := unsafe { values[1] }
	b := unsafe { values[2] }
	c := unsafe { values[3] }
	if operation < 0 || operation > 3 || a < 0 || a > 1000 || b < 0 || b > 1000 || c < 0 || c > 1000 {
		return -1.0e300
	}
	if operation == 0 || operation == 1 {
		if c == 0 { return -1.0e300 }
		return (f64(a) * f64(b) * 8.314462) / f64(c)
	}
	if a == 0 { return -1.0e300 }
	return (f64(c) * f64(b)) / (f64(a) * 8.314462)
}
