package photoelectric_effect

import "core:c"

@(export)
photoelectric_effect :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	frequency := values[0]
	work_function := values[1]
	if frequency < 0 || frequency > 1000000000000000000 || work_function < 0 || work_function > 1000 do return -1.0e300
	planck_ev: f64 = 4.1357e-15
	photon_energy := planck_ev * f64(frequency)
	energy_difference := photon_energy - f64(work_function)
	if energy_difference > 0.0 do return energy_difference
	return 0.0
}
