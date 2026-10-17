module shree_dharacharya_formula;

extern fn double sqrt(double value);

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long shree_dharacharya_formula(long* input, usz length, char* output, usz capacity)
    @export("shree_dharacharya_formula") {
    if (input == null || length != 3) return -1;
    for (usz index = 0; index < 3; index++)
        if (input[index] < -1000000 || input[index] > 1000000) return -1;
    if (input[0] == 0) return -1;
    double a = (double)input[0], b = (double)input[1], c = (double)input[2];
    double discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) return -1;
    if (output == null || capacity < 16) return -2;
    double root = sqrt(discriminant);
    double denominator = 2.0 * a;
    double first = (-b + root) / denominator;
    double second = (-b - root) / denominator;
    write_f64_le(output, 0, first);
    write_f64_le(output, 8, second);
    return 16;
}
