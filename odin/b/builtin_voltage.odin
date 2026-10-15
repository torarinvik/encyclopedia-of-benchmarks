package builtin_voltage

import "core:c"
import "core:math"

@(export)
builtin_voltage :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	donor := values[0]
	acceptor := values[1]
	intrinsic := values[2]
	if donor < 1 || donor > 1000 || acceptor < 1 || acceptor > 1000 || intrinsic < 1 || intrinsic > 1000 || donor <= intrinsic || acceptor <= intrinsic do return -1.0e300
	boltzmann: f64 = 1.380649e-23
	electron_volt: f64 = 1.602176634e-19
	ratio := (f64(donor) * f64(acceptor)) / (f64(intrinsic) * f64(intrinsic))
	return boltzmann * 300.0 * math.ln_f64(ratio) / electron_volt
}
