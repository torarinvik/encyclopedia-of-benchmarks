module transformations_2d;

extern fn double cos(double value);
extern fn double sin(double value);

const double INVALID_RESULT = -1.0e300;

fn double transformations_2d(long* values, usz length) @export("transformations_2d") {
    if (values == null || length != 3) return INVALID_RESULT;
    long operation = values[0], parameter_micro = values[1], component = values[2];
    if (operation < 0 || operation > 3 || component < 0 || component > 3) return INVALID_RESULT;

    double m0, m1, m2, m3;
    if (operation == 0) {
        if (parameter_micro < -1000000 || parameter_micro > 1000000) return INVALID_RESULT;
        double factor = (double)parameter_micro / 1000000.0;
        m0 = factor * 1.0; m1 = factor * 0.0;
        m2 = factor * 0.0; m3 = factor * 1.0;
    } else {
        if (parameter_micro < -6283185 || parameter_micro > 6283185) return INVALID_RESULT;
        double angle = (double)parameter_micro / 1000000.0;
        double c = cos(angle), s = sin(angle);
        if (operation == 1) {
            m0 = c; m1 = -s;
            m2 = s; m3 = c;
        } else {
            double cs = c * s;
            if (operation == 2) {
                m0 = c * c; m1 = cs;
                m2 = cs; m3 = s * s;
            } else {
                m0 = 2.0 * c - 1.0; m1 = 2.0 * cs;
                m2 = 2.0 * cs; m3 = 2.0 * s - 1.0;
            }
        }
    }
    if (component == 0) return m0;
    if (component == 1) return m1;
    if (component == 2) return m2;
    return m3;
}
