module farey_approximation;

fn void store_i64_le(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[position + byte] = (char)(bits & 0xff);
        bits >>= 8;
    }
}

fn long farey_approximation(long* values, usz length, char* output, usz output_capacity) @export("farey_approximation") {
    if (values == null || length != 2) return -1;
    long decimal_millionths = values[0];
    long repeat = values[1];
    if (decimal_millionths < 1 || decimal_millionths > 999999 || repeat < 1 || repeat > 20) return -1;
    if (output == null || output_capacity < 16) return -2;

    double decimal = (double)decimal_millionths / 1000000.0;
    long a = 0, b = 1, c = 1, d = 1;
    long numerator = 0, denominator = 0;
    for (long i = 0; i < repeat; i += 1) {
        numerator = a + c;
        denominator = b + d;
        if (decimal > (double)numerator / (double)denominator) {
            a = numerator;
            b = denominator;
        } else {
            c = numerator;
            d = denominator;
        }
    }
    store_i64_le(output, 0, numerator);
    store_i64_le(output, 8, denominator);
    return 16;
}
