module circular_convolution;

fn long circular_convolution(long* values, usz length, char* output, usz output_capacity) @export("circular_convolution") {
    if (values == null || length < 4) return -1;
    long raw_a_length = values[0];
    long raw_b_length = values[1];
    if (raw_a_length < 1 || raw_a_length > 8 || raw_b_length < 1 || raw_b_length > 8) return -1;
    usz a_length = (usz)raw_a_length;
    usz b_length = (usz)raw_b_length;
    if (length != 2 + a_length + b_length) return -1;
    for (usz i = 0; i < a_length + b_length; i += 1) {
        if (values[2 + i] < -2 || values[2 + i] > 2) return -1;
    }
    usz n = a_length > b_length ? a_length : b_length;
    if (output == null || output_capacity < n) return -2;

    for (usz k = 0; k < n; k += 1) {
        long sum = 0;
        for (usz i = 0; i < n; i += 1) {
            usz b_index = (k + n - i) % n;
            long a_value = i < a_length ? values[2 + i] : 0;
            long b_value = b_index < b_length ? values[2 + a_length + b_index] : 0;
            sum += a_value * b_value;
        }
        output[k] = (char)(sum < 0 ? sum + 256 : sum);
    }
    return (long)n;
}
