module ideal_gas_law

// Pressure from the ideal gas law: n * T * R / V.
@[export: 'ideal_gas_law']
pub fn ideal_gas_law(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	moles := unsafe { values[0] }
	kelvin := unsafe { values[1] }
	volume := unsafe { values[2] }
	if moles < 0 || moles > 1000 || kelvin < 0 || kelvin > 1000 || volume < 1 || volume > 1000 {
		return -1.0e300
	}
	return (f64(moles) * f64(kelvin) * 8.314462) / f64(volume)
}
