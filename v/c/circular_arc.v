module circular_arc

@[export: 'circular_arc']
pub fn circular_arc(input &i64, length usize) f64 {
	if unsafe { input == nil } || length != 3 { return -1.0e300 }
	unsafe {
		mode, radius, degrees := input[0], input[1], input[2]
		if (mode != 0 && mode != 1) || radius < -1_000_000 || radius > 1_000_000 || degrees < -360_000 || degrees > 360_000 { return -1.0e300 }
		angle := f64(degrees) * (3.14159265358979323846 / 180.0)
		if mode == 0 { return f64(radius) * angle }
		return f64(radius * radius) * angle / 2.0
	}
}
