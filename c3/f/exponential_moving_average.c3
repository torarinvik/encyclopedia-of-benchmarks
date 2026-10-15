module exponential_moving_average;

fn void put_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long exponential_moving_average(long* input, usz length, char* output, usz capacity) @export("exponential_moving_average") {
    if (input == null || length < 3) return -1;
    long window_value = input[0], count_value = input[1];
    if (window_value < 2 || window_value > 32 || count_value < 1 || count_value > 256) return -1;
    usz window = (usz)window_value, count = (usz)count_value;
    if (length != count + 2) return -1;
    for (usz i = 0; i < count; i++) if (input[2 + i] < -1000000 || input[2 + i] > 1000000) return -1;
    if (output == null || capacity < count * 8) return -2;
    double alpha = 2.0 / (1.0 + (double)window);
    double average = 0.0;
    for (usz i = 0; i < count; i++) {
        double price = (double)input[2 + i];
        if (i == 0) average = price;
        else if (i <= window) average = (average + price) * 0.5;
        else average = (alpha * price) + ((1.0 - alpha) * average);
        put_f64_le(average, output, i * 8);
    }
    return (long)(count * 8);
}
