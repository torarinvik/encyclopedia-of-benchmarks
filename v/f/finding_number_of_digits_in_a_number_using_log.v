module finding_number_of_digits_in_a_number_using_log

import math

const max_abs_value = i64(1_000_000)

@[export: 'finding_number_of_digits_in_a_number_using_log']
pub fn finding_number_of_digits_in_a_number_using_log(value i64) i64 {
	if value < -max_abs_value || value > max_abs_value { return -1 }
	if value == 0 { return 0 }
	return i64(math.floor(math.log10(math.abs(f64(value))) + 1.0))
}
