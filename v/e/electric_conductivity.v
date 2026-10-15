module electric_conductivity

@[export: 'electric_conductivity']
pub fn electric_conductivity(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	conductivity := unsafe { values[0] }
	electron_conc := unsafe { values[1] }
	mobility := unsafe { values[2] }
	if conductivity < 0 || conductivity > 1000 || electron_conc < 0 || electron_conc > 1000 || mobility < 0 || mobility > 1000 { return -1.0e300 }
	mut zeros := 0
	if conductivity == 0 { zeros++ }
	if electron_conc == 0 { zeros++ }
	if mobility == 0 { zeros++ }
	if zeros != 1 { return -1.0e300 }
	charge := 1.6021e-19
	if conductivity == 0 { return f64(mobility) * f64(electron_conc) * charge }
	if electron_conc == 0 { return f64(conductivity) / (f64(mobility) * charge) }
	return f64(conductivity) / (f64(electron_conc) * charge)
}
