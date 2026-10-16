module present_value_rust

import math

const max_cash_flows = i64(8)
const max_rate_ppm = i64(1_000_000)
const max_cash_flow_milli = i64(1_000_000)
const max_input_length = usize(11)
const invalid_result = -1.0e300

@[export: 'present_value_rust']
pub fn present_value_rust(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 3 || length > max_input_length { return invalid_result }
	count, rate_ppm := unsafe { values[0] }, unsafe { values[1] }
	if count < 1 || count > max_cash_flows || length != usize(count + 2) || (rate_ppm != 0 && rate_ppm != max_rate_ppm) { return invalid_result }

	discount_rate := f64(rate_ppm) / 1_000_000.0
	mut present_value := 0.0
	for index in 0 .. int(count) {
		cash_flow_milli := unsafe { values[index + 2] }
		if cash_flow_milli < -max_cash_flow_milli || cash_flow_milli > max_cash_flow_milli || cash_flow_milli % 125 != 0 { return invalid_result }
		cash_flow := f64(cash_flow_milli) / 1_000.0
		present_value += cash_flow / math.pow(1.0 + discount_rate, f64(index))
	}
	return math.round(present_value * 100.0) / 100.0
}
