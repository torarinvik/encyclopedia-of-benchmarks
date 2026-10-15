package square_root_with_babylonian_method

@(export)
square_root_with_babylonian_method :: proc "c" (input: f64) -> f64 {
	if !(input >= 1.0 && input <= 1000000.0) do return -1.0
	num := f32(input)
	a := num
	b := f32(1.0)
	epsilon := 0.000001
	for f64(a - b) > epsilon {
		a = (a + b) / f32(2.0)
		b = num / a
	}
	return f64(a)
}
