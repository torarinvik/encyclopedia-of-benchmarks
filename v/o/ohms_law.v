module ohms_law

@[export: 'ohms_law']
pub fn ohms_law(voltage f64, current f64, resistance f64) f64 {
	if voltage != voltage || current != current || resistance != resistance { return -1e300 }
	if voltage < -1000.0 || voltage > 1000.0 || current < -1000.0 || current > 1000.0 || resistance < 0.0 || resistance > 1000.0 { return -1e300 }
	if voltage != f64(i64(voltage)) || current != f64(i64(current)) || resistance != f64(i64(resistance)) { return -1e300 }
	mut zeros := 0
	if voltage == 0.0 { zeros++ }
	if current == 0.0 { zeros++ }
	if resistance == 0.0 { zeros++ }
	if zeros != 1 { return -1e300 }
	if voltage == 0.0 { return current * resistance }
	if current == 0.0 { return voltage / resistance }
	return voltage / current
}
