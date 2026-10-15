module vector_cross_product;

extern fn double sqrt(double value);

fn void store_i64_le(long value, char* output, usz position) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[position + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long vector_cross_product(long* input, usz input_length, char* output,
        usz output_capacity) @export("vector_cross_product") {
    if (input == null || input_length != 6) return -1;
    for (usz i = 0; i < 6; i++) if (input[i] < -1000000 || input[i] > 1000000) return -1;
    long x = input[1] * input[5] - input[2] * input[4];
    long y = -((input[0] * input[5]) - (input[2] * input[3]));
    long z = input[0] * input[4] - input[1] * input[3];
    double magnitude = sqrt((double)x * (double)x + (double)y * (double)y + (double)z * (double)z);
    long magnitude_micro = (long)(magnitude * 1000000.0 + 0.5);
    if (output == null || output_capacity < 32) return -2;
    store_i64_le(x, output, 0); store_i64_le(y, output, 8);
    store_i64_le(z, output, 16); store_i64_le(magnitude_micro, output, 24);
    return 32;
}
