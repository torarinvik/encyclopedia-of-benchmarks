module time_converter

const scale = i64(1_000_000)
const max_time_micro = i64(1_000_000_000)
const max_input_length = usize(4)
const invalid_result = -1.0e300

fn seconds_per_unit(unit i64) f64 {
	return match unit {
		0 { 1.0 }
		1 { 60.0 }
		2 { 3600.0 }
		3 { 86400.0 }
		4 { 604800.0 }
		5 { 2629800.0 }
		6 { 31557600.0 }
		else { 0.0 }
	}
}

@[export: 'time_converter']
pub fn time_converter(values &i64, length usize) f64 {
	if length != 3 || length > max_input_length || unsafe { values == nil } { return invalid_result }
	time_micro, from_unit, to_unit := unsafe { values[0] }, unsafe { values[1] }, unsafe { values[2] }
	if time_micro < 0 || time_micro > max_time_micro || from_unit < 0 || from_unit > 6 || to_unit < 0 || to_unit > 6 { return invalid_result }
	time_value := f64(time_micro) / f64(scale)
	seconds_value := time_value * seconds_per_unit(from_unit)
	converted := seconds_value / seconds_per_unit(to_unit)
	rounded := i64(converted * 1000.0 + 0.5)
	return f64(rounded) / 1000.0
}
