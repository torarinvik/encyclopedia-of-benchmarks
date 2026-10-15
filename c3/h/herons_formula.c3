module herons_formula;

extern fn double floor(double value);
extern fn double sqrt(double value);

const double SIDE_LIMIT = 1000000.0;

fn double herons_formula(double a, double b, double c) @export("herons_formula") {
    if (a < 1.0 || a > SIDE_LIMIT || floor(a) != a ||
        b < 1.0 || b > SIDE_LIMIT || floor(b) != b ||
        c < 1.0 || c > SIDE_LIMIT || floor(c) != c ||
        a + b <= c || b + c <= a || c + a <= b) return -1.0;

    double s = (a + b + c) / 2.0;
    return sqrt((s) * (s - a) * (s - b) * (s - c));
}

