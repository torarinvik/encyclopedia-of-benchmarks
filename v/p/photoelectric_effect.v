module photoelectric_effect

@[export: 'photoelectric_effect']
pub fn photoelectric_effect(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	frequency := unsafe { values[0] }
	work_function := unsafe { values[1] }
	if frequency < 0 || frequency > 1000000000000000000 || work_function < 0 || work_function > 1000 { return -1.0e300 }
	planck_ev := 4.1357e-15
	photon_energy := planck_ev * f64(frequency)
	energy_difference := photon_energy - f64(work_function)
	if energy_difference > 0.0 { return energy_difference }
	return 0.0
}
