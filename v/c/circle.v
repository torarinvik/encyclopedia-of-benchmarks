module circle

const invalid_result = -1.0e300
const pi = 3.14159265358979323846

// Perimeter and area calculations for a bounded circle radius.
@[export: 'circle']
pub fn circle(radius f64, operation f64) f64 {
	if !(radius >= -1_000_000.0 && radius <= 1_000_000.0 && (operation == 0.0 || operation == 1.0)) {
		return invalid_result
	}
	if operation == 0.0 { return radius * 2.0 * pi }
	return radius * radius * pi
}
