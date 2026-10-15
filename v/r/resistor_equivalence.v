module resistor_equivalence

@[export: 'resistor_equivalence']
pub fn resistor_equivalence(values &i64, length usize) f64 {
	if length < 2 || length > 33 { return -1.0e300 }
	operation := unsafe { values[0] }
	if operation != 0 && operation != 1 { return -1.0e300 }
	mut accumulated := 0.0
	mut index := usize(1)
	for index < length {
		resistor := unsafe { values[index] }
		if (operation == 0 && resistor < 1) || (operation == 1 && resistor < 0) || resistor > 1000 {
			return -1.0e300
		}
		if operation == 0 { accumulated += 1.0 / f64(resistor) }
		else { accumulated += f64(resistor) }
		index += 1
	}
	if operation == 0 { return 1.0 / accumulated }
	return accumulated
}
