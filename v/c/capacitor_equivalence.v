module capacitor_equivalence

@[export: 'capacitor_equivalence']
pub fn capacitor_equivalence(values &i64, length usize) f64 {
	if length < 2 || length > 33 { return -1.0e300 }
	operation := unsafe { values[0] }
	if operation != 0 && operation != 1 { return -1.0e300 }
	mut accumulated := 0.0
	mut index := usize(1)
	for index < length {
		capacitor := unsafe { values[index] }
		if (operation == 0 && capacitor < 0) || (operation == 1 && capacitor < 1) || capacitor > 1000 {
			return -1.0e300
		}
		if operation == 0 { accumulated += f64(capacitor) }
		else { accumulated += 1.0 / f64(capacitor) }
		index += 1
	}
	if operation == 0 { return accumulated }
	return 1.0 / accumulated
}
