module charging_capacitor

import math

const invalid_result = -1.0e300

fn round_three_python(value f64) f64 {
	if value == 0.0 { return value }
	negative := value < 0.0
	mut normalized := if negative { -value } else { value }
	mut exponent := 0
	for normalized >= 1.0 { normalized *= 0.5; exponent++ }
	for normalized < 0.5 { normalized *= 2.0; exponent-- }
	significand := u64(normalized * 9_007_199_254_740_992.0)
	numerator := significand * u64(1000)
	shift := 53 - exponent
	mut milliunits := u64(0)
	if shift < 0 { milliunits = numerator << u32(-shift) }
	else if shift == 0 { milliunits = numerator }
	else if shift < 64 {
		denominator := u64(1) << u32(shift)
		milliunits = numerator >> u32(shift)
		remainder := numerator & (denominator - 1)
		half := denominator >> 1
		if remainder > half || (remainder == half && (milliunits & u64(1)) != 0) { milliunits++ }
	}
	rounded := f64(milliunits) / 1000.0
	if negative { return -rounded }
	return rounded
}

@[export: 'charging_capacitor']
pub fn charging_capacitor(values &i64, length usize) f64 {
	if length != 4 { return invalid_result }
	unsafe {
		if values == nil { return invalid_result }
		voltage_micro := values[0]
		resistance_micro := values[1]
		capacitance_micro := values[2]
		time_micro := values[3]
		if voltage_micro < 1 || voltage_micro > i64(1_000_000_000_000) ||
			resistance_micro < 1 || resistance_micro > i64(1_000_000_000_000_000) ||
			capacitance_micro < 1 || capacitance_micro > i64(1_000_000_000_000) ||
			time_micro < -i64(1_000_000_000_000) || time_micro > i64(1_000_000_000_000) {
			return invalid_result
		}
		source_voltage := f64(voltage_micro) / 1_000_000.0
		resistance := f64(resistance_micro) / 1_000_000.0
		capacitance := f64(capacitance_micro) / 1_000_000.0
		time_sec := f64(time_micro) / 1_000_000.0
		exponent := -time_sec / (resistance * capacitance)
		if exponent > 10.0 { return invalid_result }
		return round_three_python(source_voltage * (1.0 - math.exp(exponent)))
	}
}
