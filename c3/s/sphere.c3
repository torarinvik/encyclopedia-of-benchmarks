module sphere;

const double INVALID_RESULT = -1.0e300;
const double PI = 3.14159265358979323846;

fn double sphere(int64* input, usz length) @export("sphere") {
    if (input == null || length != 2) return INVALID_RESULT;
    int64 mode = input[0];
    int64 radius = input[1];
    if ((mode != 0 && mode != 1) || radius < 0 || radius > 1000000) return INVALID_RESULT;
    double r = (double)radius;
    double r2 = r * r;
    if (mode == 0) return (((r2 * r) * PI) * 4.0) / 3.0;
    return (r2 * PI) * 4.0;
}
