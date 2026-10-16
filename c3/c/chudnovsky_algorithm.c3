module chudnovsky_algorithm;

const MAX_PRECISION = 12;

fn double sqrt_10005() {
    double root = 100.0;
    for (int iteration = 0; iteration < 8; iteration++) root = 0.5 * (root + 10005.0 / root);
    return root;
}

fn long chudnovsky_algorithm(long* values, usz length, char* output, usz capacity)
    @export("chudnovsky_algorithm") {
    if (values == null || length != 1 || values[0] < 1 || values[0] > MAX_PRECISION) return -1;
    usz precision = (usz)values[0];
    usz output_length = precision == 1 ? 0 : precision;
    if (capacity < output_length || (output_length > 0 && output == null)) return -2;
    if (precision == 1) return 0;

    double pi = (426880.0 * sqrt_10005()) / 13591409.0;
    double fraction = pi - 3.0;
    output[0] = '3';
    output[1] = '.';
    for (usz digit = 0; digit < precision - 2; digit++) {
        fraction *= 10.0;
        int next_digit = (int)fraction;
        output[2 + digit] = (char)('0' + next_digit);
        fraction -= (double)next_digit;
    }
    return (long)output_length;
}
