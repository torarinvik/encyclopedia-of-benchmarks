module adams_bashforth;

fn long coefficient(long order, usz offset) {
    if (order == 2) return offset == 0 ? 3 : -1;
    if (order == 3) return offset == 0 ? 23 : offset == 1 ? -16 : 5;
    if (order == 4) return offset == 0 ? 55 : offset == 1 ? -59 : offset == 2 ? 37 : -9;
    return offset == 0 ? 1901 : offset == 1 ? -2774 : offset == 2 ? -2616 : offset == 3 ? -1274 : 251;
}

fn usz append_integer(long value, char* out, usz position) {
    char[24] digits;
    usz count = 0;
    if (value < 0) { out[position++] = '-'; value = -value; }
    do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value > 0);
    while (count > 0) { count--; out[position++] = digits[count]; }
    return position;
}

fn long adams_bashforth(long* values, usz length, char* output, usz output_capacity)
        @export("adams_bashforth") {
    if (values == null || length < 4) return -1;
    long order = values[0], steps = values[1];
    if (order < 2 || order > 5 || steps < 1 || steps > 4 || length != (usz)order + 2) return -1;
    double[14] x, y;
    for (usz i = 0; i < (usz)order; i++) {
        if (values[i + 2] < -100000 || values[i + 2] > 100000) return -1;
        x[i] = (double)i * 0.25;
        y[i] = (double)values[i + 2] / 100000.0;
    }
    long denominator = order == 2 ? 2 : order == 3 ? 12 : order == 4 ? 24 : 720;
    usz iterations = (usz)steps + ((order == 3 || order == 5) ? 1 : 0);
    usz count = (usz)order;
    for (usz iteration = 0; iteration < iterations; iteration++) {
        double weighted = 0.0;
        for (usz offset = 0; offset < (usz)order; offset++) {
            usz index = count - 1 - offset;
            weighted += (double)coefficient(order, offset) * (x[index] + y[index]);
        }
        y[count] = y[count - 1] + (0.25 / (double)denominator) * weighted;
        x[count] = x[count - 1] + 0.25;
        count++;
    }
    char[256] encoded;
    usz position = 0;
    for (usz i = 0; i < count; i++) {
        if (i > 0) encoded[position++] = ',';
        position = append_integer((long)(y[i] * 1000000.0), &encoded, position);
    }
    if (output == null || output_capacity < position) return -2;
    for (usz i = 0; i < position; i++) output[i] = encoded[i];
    return (long)position;
}
