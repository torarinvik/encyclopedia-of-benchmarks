module square_root_with_babylonian_method

@[export: 'square_root_with_babylonian_method']
pub fn square_root_with_babylonian_method(input f64) f64 {
	if !(input >= 1.0 && input <= 1000000.0) { return -1.0 }
	num := f32(input)
	mut a := num
	mut b := f32(1.0)
	epsilon := 0.000001
	for f64(a - b) > epsilon {
		a = (a + b) / f32(2.0)
		b = num / a
	}
	return f64(a)
}
