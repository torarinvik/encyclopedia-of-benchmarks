module arc_length;

const PI = 3.141592653589793238462643383279502884;

// Return arc length; unit 0 uses degrees and unit 1 uses radians.
fn double arc_length(double radius, double angle, double unit) @export("arc_length") {
    return unit == 0.0 ? 2.0 * PI * radius * (angle / 360.0) : radius * angle;
}
