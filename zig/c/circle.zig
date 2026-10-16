/// Perimeter and area calculations for a bounded circle radius.
const INVALID_RESULT: f64 = -1.0e300;
const PI: f64 = 3.14159265358979323846;

export fn circle(radius: f64, operation: f64) f64 {
    if (!std_math_isFinite(radius) or !std_math_isFinite(operation) or
        radius < -1_000_000.0 or radius > 1_000_000.0 or
        (operation != 0.0 and operation != 1.0)) return INVALID_RESULT;
    if (operation == 0.0) return radius * 2.0 * PI;
    return radius * radius * PI;
}

fn std_math_isFinite(value: f64) bool {
    return @abs(value) <= 1.7976931348623157e308;
}
