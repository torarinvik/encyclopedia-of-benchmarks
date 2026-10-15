module wheatstone_bridge

@[export: 'wheatstone_bridge']
pub fn wheatstone_bridge(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	resistance_1 := unsafe { values[0] }
	resistance_2 := unsafe { values[1] }
	resistance_3 := unsafe { values[2] }
	if resistance_1 < 1 || resistance_1 > 1_000_000 || resistance_2 < 1 || resistance_2 > 1_000_000 || resistance_3 < 1 || resistance_3 > 1_000_000 { return -1.0e300 }
	return (f64(resistance_2) / f64(resistance_1)) * f64(resistance_3)
}
