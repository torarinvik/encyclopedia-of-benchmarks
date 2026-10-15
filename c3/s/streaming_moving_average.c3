module streaming_moving_average;
fn void put_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}
fn long streaming_moving_average(long* input, usz length, char* output, usz capacity) @export("streaming_moving_average") {
    if (input == null || length < 3) return -1;
    long window_value = input[0], count_value = input[1];
    if (window_value < 1 || window_value > 256 || count_value < 1 || count_value > 256) return -1;
    usz window = (usz)window_value, count = (usz)count_value;
    if (length != count + 2) return -1;
    for (usz i = 0; i < count; i++) if (input[2 + i] < -2147483648 || input[2 + i] > 2147483647) return -1;
    if (capacity < count * 8 || output == null) return -2;
    for (usz i = 0; i < count; i++) {
        usz start = i + 1 > window ? i + 1 - window : 0;
        long sum = 0;
        for (usz j = start; j <= i; j++) sum += input[2 + j];
        put_f64_le((double)sum / (double)(i + 1 - start), output, i * 8);
    }
    return (long)(count * 8);
}
