module bisection_2

const invalid_result = -1.0e300
const max_endpoint_milli = i64(100000)

fn equation(x f64) f64 { return 10.0 - x * x }

@[export: 'bisection_2']
pub fn bisection_2(input &i64, length usize) f64 {
	if unsafe { input == nil } || length != 2 { return invalid_result }
	left_milli := unsafe { input[0] }
	right_milli := unsafe { input[1] }
	if left_milli < -max_endpoint_milli || left_milli > max_endpoint_milli || right_milli < -max_endpoint_milli || right_milli > max_endpoint_milli || left_milli >= right_milli {
		return invalid_result
	}
	mut a := f64(left_milli) / 1000.0
	mut b := f64(right_milli) / 1000.0
	if equation(a) * equation(b) >= 0.0 { return invalid_result }
	mut c := a
	for b - a >= 0.01 {
		c = (a + b) / 2.0
		if equation(c) == 0.0 { break }
		if equation(c) * equation(a) < 0.0 { b = c }
		else { a = c }
	}
	return c
}
