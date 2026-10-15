module geometric_series;
fn void put_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}
fn long geometric_series(long* input, usz length, char* output, usz capacity) @export("geometric_series") {
    if (input == null || length != 3 || input[0] < 0 || input[0] > 16 || input[1] < 1 || input[1] > 8 || input[2] < 1 || input[2] > 4) return -1;
    usz n = (usz)input[0]; if (capacity < n * 8 || (n > 0 && output == null)) return -2;
    double term = (double)input[1], ratio = (double)input[2];
    for (usz i = 0; i < n; i++) { put_f64_le(term, output, i * 8); term *= ratio; }
    return (long)(n * 8);
}
