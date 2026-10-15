module sphere

const invalid_result = -1.0e300
const pi = 3.14159265358979323846

@[export: 'sphere']
pub fn sphere(input &i64, length usize) f64 {
	if isnil(input) || length != 2 { return invalid_result }
	mode := unsafe { input[0] }
	radius := unsafe { input[1] }
	if (mode != 0 && mode != 1) || radius < 0 || radius > 1_000_000 { return invalid_result }
	r := f64(radius)
	r2 := r * r
	if mode == 0 { return (((r2 * r) * pi) * 4.0) / 3.0 }
	return (r2 * pi) * 4.0
}
