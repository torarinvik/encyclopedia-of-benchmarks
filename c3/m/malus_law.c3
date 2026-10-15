module malus_law;

extern fn double cos(double value);
const double PI = 3.141592653589793238462643383279502884;
const double INVALID_RESULT = -1.0e300;

fn double malus_law(long* values, usz length) @export("malus_law") {
    if (values == null || length != 2) return INVALID_RESULT;
    long initial_intensity = values[0];
    long angle = values[1];
    if (initial_intensity < 0 || initial_intensity > 1000 || angle < 0 || angle > 360)
        return INVALID_RESULT;
    double radians = ((double)angle * PI) / 180.0;
    double cosine = cos(radians);
    return (double)initial_intensity * (cosine * cosine);
}
