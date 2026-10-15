module ind_reactance

@[export: 'ind_reactance']
pub fn ind_reactance(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	inductance := unsafe { values[0] }
	frequency := unsafe { values[1] }
	reactance := unsafe { values[2] }
	if inductance < 0 || inductance > 1000 || frequency < 0 || frequency > 1000 || reactance < 0 || reactance > 1000 { return -1.0e300 }
	mut zeros := 0
	if inductance == 0 { zeros++ }
	if frequency == 0 { zeros++ }
	if reactance == 0 { zeros++ }
	if zeros != 1 { return -1.0e300 }
	pi := 3.14159265358979323846
	if inductance == 0 { return f64(reactance) / (2.0 * pi * f64(frequency)) }
	if frequency == 0 { return f64(reactance) / (2.0 * pi * f64(inductance)) }
	return 2.0 * pi * f64(frequency) * f64(inductance)
}
