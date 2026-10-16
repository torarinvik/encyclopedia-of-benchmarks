module vector2;

extern fn double floor(double value);
extern fn double fabs(double value);
extern fn double sqrt(double value);
extern fn double cos(double value);
extern fn double sin(double value);
extern fn double atan2(double y, double x);

fn long vector2(double* values, usz length, double* output, usz capacity) @export("vector2") {
    if (values == null || length != 6) return -1;
    for (usz i = 0; i < length; i++) if (values[i] != values[i] || values[i] > 1.0e100 || values[i] < -1.0e100) return -1;
    if (values[0] < 0.0 || values[0] > 10.0 || floor(values[0]) != values[0]) return -1;
    for (usz i = 1; i <= 4; i++) if (values[i] < -1000.0 || values[i] > 1000.0) return -1;

    int op = (int)values[0];
    double ax = values[1], ay = values[2], bx = values[3], by = values[4], scalar = values[5];
    if (op == 1) {
        if (scalar < 0.0 || scalar > 2000.0) return -1;
    } else if (op == 6) {
        if (bx != 0.0 || by != 0.0 || scalar < -1000.0 || scalar > 1000.0) return -1;
    } else if (op == 9) {
        if (bx != 0.0 || by != 0.0 || scalar < -6.283185307179586 || scalar > 6.283185307179586) return -1;
    } else if (scalar != 0.0) return -1;
    if ((op == 2 || op == 3) && (bx != 0.0 || by != 0.0)) return -1;

    double[2] result;
    result[0] = 0.0;
    result[1] = 0.0;
    usz result_length = 1;
    if (op == 0) result[0] = if (ax == bx && ay == by) 1.0 else 0.0;
    else if (op == 1) result[0] = if (fabs(ax - bx) < scalar && fabs(ay - by) < scalar) 1.0 else 0.0;
    else if (op == 2) result[0] = sqrt(ax * ax + ay * ay);
    else if (op == 3) {
        double magnitude = sqrt(ax * ax + ay * ay);
        if (magnitude == 0.0) return -1;
        result_length = 2;
        result[0] = ax / magnitude;
        result[1] = ay / magnitude;
    } else if (op == 4) {
        result_length = 2; result[0] = ax + bx; result[1] = ay + by;
    } else if (op == 5) {
        result_length = 2; result[0] = ax - bx; result[1] = ay - by;
    } else if (op == 6) {
        result_length = 2; result[0] = ax * scalar; result[1] = ay * scalar;
    } else if (op == 7) {
        double dx = bx - ax, dy = by - ay;
        result[0] = sqrt(dx * dx + dy * dy);
    } else if (op == 8) result[0] = ax * bx + ay * by;
    else if (op == 9) {
        double cosine = cos(scalar), sine = sin(scalar);
        result_length = 2;
        result[0] = cosine * ax - sine * ay;
        result[1] = sine * ax + cosine * ay;
    } else result[0] = atan2(by, bx) - atan2(ay, ax);

    if (output == null || capacity < result_length) return -2;
    for (usz i = 0; i < result_length; i++) output[i] = result[i];
    return (long)result_length;
}
