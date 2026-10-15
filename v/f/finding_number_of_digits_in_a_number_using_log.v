module finding_number_of_digits_in_a_number_using_log

import math

const max_abs_value = 1_000_000.0
const invalid_result = -1.0e300

@[export: 'finding_number_of_digits_in_a_number_using_log']
pub fn finding_number_of_digits_in_a_number_using_log(value f64) f64 {
	if !(value >= -max_abs_value && value <= max_abs_value) { return invalid_result }
	if value == 0.0 { return 0.0 }
	return math.floor(math.log10(math.abs(value)) + 1.0)
}
