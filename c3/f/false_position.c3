module false_position;

fn double function_value(double x) {
    return x * x - x;
}

fn double absolute(double x) {
    return x < 0.0 ? -x : x;
}

fn double false_position(double a, double b) @export("false_position") {
    if (a != a || b != b || a < 0.125 || a > 0.875 ||
        !((b >= -2.0 && b <= -0.125) || (b >= 1.125 && b <= 3.0))) return -1.0;
    double fa = function_value(a);
    double fb = function_value(b);
    if (!(fa < 0.0 && fb > 0.0)) return -1.0;
    double c = b;
    for (usz iteration = 0; iteration < 256; iteration++) {
        c = b - fb * (b - a) / (fb - fa);
        double fc = function_value(c);
        if (absolute(fc) <= 1e-12) return c;
        if (fc < 0.0) {
            a = c;
            fa = fc;
        } else {
            b = c;
            fb = fc;
        }
    }
    return absolute(fa) <= absolute(fb) ? a : b;
}
