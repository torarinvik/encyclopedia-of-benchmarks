module carrier_concentration

import math

@[export: 'carrier_concentration']
pub fn carrier_concentration(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	unsafe {
		electron_conc := values[0]
		hole_conc := values[1]
		intrinsic_conc := values[2]
		if electron_conc < 0 || electron_conc > 1000000 || hole_conc < 0 || hole_conc > 1000000 || intrinsic_conc < 0 || intrinsic_conc > 1000000 { return -1.0e300 }
		zero_count := i32(electron_conc == 0) + i32(hole_conc == 0) + i32(intrinsic_conc == 0)
		if zero_count != 1 { return -1.0e300 }
		if electron_conc == 0 { return f64(intrinsic_conc * intrinsic_conc) / f64(hole_conc) }
		if hole_conc == 0 { return f64(intrinsic_conc * intrinsic_conc) / f64(electron_conc) }
		return math.pow(f64(electron_conc * hole_conc), 0.5)
	}
}
