module arc_length

const pi64 = 3.141592653589793238462643383279502884

// Return arc length; unit 0 uses degrees and unit 1 uses radians.
@[export: 'arc_length']
pub fn arc_length(radius f64, angle f64, unit f64) f64 {
	if unit == 0.0 {
		return 2.0 * pi64 * radius * (angle / 360.0)
	}
	return radius * angle
}
