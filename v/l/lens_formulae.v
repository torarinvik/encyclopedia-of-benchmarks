module lens_formulae

@[export: 'lens_formulae']
pub fn lens_formulae(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	unsafe {
		operation := values[0]
		first := values[1]
		second := values[2]
		if operation < 0 || operation > 2 || first == 0 || second == 0 || first < -1000000 || first > 1000000 || second < -1000000 || second > 1000000 { return -1.0e300 }
		if operation == 0 {
			if first == second { return -1.0e300 }
			return 1.0 / ((1.0 / f64(second)) - (1.0 / f64(first)))
		}
		if operation == 1 {
			if first == second { return -1.0e300 }
			return 1.0 / ((1.0 / f64(second)) - (1.0 / f64(first)))
		}
		if first == -second { return -1.0e300 }
		return 1.0 / ((1.0 / f64(second)) + (1.0 / f64(first)))
	}
}
