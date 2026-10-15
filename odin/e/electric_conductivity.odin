package electric_conductivity

import "core:c"

@(export)
electric_conductivity :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	conductivity := values[0]
	electron_conc := values[1]
	mobility := values[2]
	if conductivity < 0 || conductivity > 1000 || electron_conc < 0 || electron_conc > 1000 || mobility < 0 || mobility > 1000 do return -1.0e300
	zeros := 0
	if conductivity == 0 do zeros += 1
	if electron_conc == 0 do zeros += 1
	if mobility == 0 do zeros += 1
	if zeros != 1 do return -1.0e300
	charge: f64 = 1.6021e-19
	if conductivity == 0 do return f64(mobility) * f64(electron_conc) * charge
	if electron_conc == 0 do return f64(conductivity) / (f64(mobility) * charge)
	return f64(conductivity) / (f64(electron_conc) * charge)
}
