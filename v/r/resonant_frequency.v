module resonant_frequency

import math

@[export: 'resonant_frequency']
pub fn resonant_frequency(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	inductance := unsafe { values[0] }
	capacitance := unsafe { values[1] }
	if inductance < 1 || inductance > 1000 || capacitance < 1 || capacitance > 1000 { return -1.0e300 }
	pi := 3.14159265358979323846
	return 1.0 / (2.0 * pi * math.sqrt(f64(inductance) * f64(capacitance)))
}
