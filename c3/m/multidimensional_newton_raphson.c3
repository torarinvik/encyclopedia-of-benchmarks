module multidimensional_newton_raphson;

extern fn double floor(double value);

const long MIN_COORDINATE = 900;
const long MAX_COORDINATE = 1500;
const long MAX_UPDATES = 8;

fn void store_i64_le(uchar *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 255ul);
        bits >>= 8;
    }
}

fn long round_nano(double value) {
    double magnitude = value < 0.0 ? -value : value;
    long rounded = (long)floor(magnitude * 1000000000.0 + 0.5);
    return value < 0.0 ? -rounded : rounded;
}

fn long multidimensional_newton_raphson(long *input, usz length,
    uchar *output, usz capacity) @export("multidimensional_newton_raphson") {
    if (input == null || length < 1 || length > 4) return -1;
    if (length != 3) return -1;
    long x_milli = input[0], y_milli = input[1], updates = input[2];
    if (x_milli < MIN_COORDINATE || x_milli > MAX_COORDINATE
            || y_milli < MIN_COORDINATE || y_milli > MAX_COORDINATE
            || updates < 1 || updates > MAX_UPDATES) return -1;
    if (output == null || capacity < 16) return -2;

    double x = (double)x_milli / 1000.0;
    double y = (double)y_milli / 1000.0;
    for (long step = 0; step < updates; step++) {
        double f1 = x * x + y - 3.0;
        double f2 = x + y * y - 3.0;
        double determinant = 4.0 * x * y - 1.0;
        double dx = (2.0 * y * f1 - f2) / determinant;
        double dy = (2.0 * x * f2 - f1) / determinant;
        x -= dx;
        y -= dy;
    }
    store_i64_le(output, 0, round_nano(x));
    store_i64_le(output, 8, round_nano(y));
    return 16;
}
