package prefix_conversions

import "core:math"

si_exponent :: proc(code: f64) -> i32 {
	if code == 0.0 do return 24
	if code == 1.0 do return 21
	if code == 2.0 do return 18
	if code == 3.0 do return 15
	if code == 4.0 do return 12
	if code == 5.0 do return 9
	if code == 6.0 do return 6
	if code == 7.0 do return 3
	if code == 8.0 do return 2
	if code == 9.0 do return 1
	if code == 10.0 do return -1
	if code == 11.0 do return -2
	if code == 12.0 do return -3
	if code == 13.0 do return -6
	if code == 14.0 do return -9
	if code == 15.0 do return -12
	if code == 16.0 do return -15
	if code == 17.0 do return -18
	if code == 18.0 do return -21
	if code == 19.0 do return -24
	return 1000
}

binary_exponent :: proc(code: f64) -> i32 {
	if code == 20.0 do return 8
	if code == 21.0 do return 7
	if code == 22.0 do return 6
	if code == 23.0 do return 5
	if code == 24.0 do return 4
	if code == 25.0 do return 3
	if code == 26.0 do return 2
	if code == 27.0 do return 1
	return 1000
}

@(export)
prefix_conversions :: proc "c" (known_amount, known_code, unknown_code: f64) -> f64 {
	if known_amount != known_amount || known_amount < -1000000.0 || known_amount > 1000000.0 do return -1e300
	known_si := si_exponent(known_code)
	unknown_si := si_exponent(unknown_code)
	if known_si != 1000 && unknown_si != 1000 do return known_amount * math.pow_f64(10.0, f64(known_si - unknown_si))
	known_binary := binary_exponent(known_code)
	unknown_binary := binary_exponent(unknown_code)
	if known_binary != 1000 && unknown_binary != 1000 do return known_amount * math.pow_f64(2.0, f64((known_binary - unknown_binary) * 10))
	return -1e300
}
