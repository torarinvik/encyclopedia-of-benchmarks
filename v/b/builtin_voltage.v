module builtin_voltage

import math

@[export: 'builtin_voltage']
pub fn builtin_voltage(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	donor := unsafe { values[0] }
	acceptor := unsafe { values[1] }
	intrinsic := unsafe { values[2] }
	if donor < 1 || donor > 1000 || acceptor < 1 || acceptor > 1000 || intrinsic < 1 || intrinsic > 1000 || donor <= intrinsic || acceptor <= intrinsic { return -1.0e300 }
	boltzmann := 1.380649e-23
	electron_volt := 1.602176634e-19
	ratio := (f64(donor) * f64(acceptor)) / (f64(intrinsic) * f64(intrinsic))
	return boltzmann * 300.0 * math.log(ratio) / electron_volt
}
