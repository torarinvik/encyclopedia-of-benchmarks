module double_point_crossover;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long double_point_crossover(long* input, usz length, char* output, usz capacity) @export("double_point_crossover") {
    if (input == null || length < 7 || length > 131) return -1;
    long n = input[0];
    long j1 = input[1];
    long j2 = input[2];
    if (n < 2 || n > 64 || length != (usz)(3 + 2 * n) || j1 < 1 || j1 >= j2 || j2 > n) return -1;
    for (usz i = 0; i < (usz)(2 * n); i++) if (input[3 + i] < -2147483648 || input[3 + i] > 2147483647) return -1;
    usz bytes = (usz)(16 * n);
    if (output == null || capacity < bytes) return -2;
    usz a = (usz)j1;
    usz b = (usz)j2;
    usz count = (usz)n;
    for (usz i = 0; i < count; i++) {
        long child1 = (i < a || i >= b) ? input[3 + i] : input[3 + count + i];
        long child2 = (i < a || i >= b) ? input[3 + count + i] : input[3 + i];
        put_i64_le(output, i * 8, child1);
        put_i64_le(output, (count + i) * 8, child2);
    }
    return (long)bytes;
}
