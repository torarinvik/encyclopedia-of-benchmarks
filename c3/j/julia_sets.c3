module julia_sets;

fn bool finite_f32(float value) {
    return value == value && value <= 3.402823466e38f && value >= -3.402823466e38f;
}

fn void put_f32(float value, char* output, usz offset) {
    uint bits = @bitcast(uint, value);
    for (usz byte = 0; byte < 4; ++byte)
        output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long julia_sets(long* input, usz length, char* output, usz capacity)
    @export("julia_sets") {
    if (input == null || length < 4 || length > 68) return -1;
    long iterations = input[0], cr_units = input[1], ci_units = input[2], count_value = input[3];
    if (iterations < 0 || iterations > 8 || count_value < 0 || count_value > 32 ||
        cr_units < -128 || cr_units > 128 || ci_units < -128 || ci_units > 128) return -1;
    usz count = (usz)count_value;
    if (length != 4 + 2 * count) return -1;
    for (usz i = 0; i < 2 * count; ++i)
        if (input[4 + i] < -128 || input[4 + i] > 128) return -1;
    usz needed = 8 * count;
    if (output == null || capacity < needed) return -2;

    float cr = (float)cr_units / 16.0f, ci = (float)ci_units / 16.0f;
    float[64] computed;
    for (usz point = 0; point < count; ++point) {
        float real = (float)input[4 + 2 * point] / 16.0f;
        float imag = (float)input[5 + 2 * point] / 16.0f;
        for (long step = 0; step < iterations; ++step) {
            float real_square = real * real;
            float imag_square = imag * imag;
            float real_imag = real * imag;
            float imag_real = imag * real;
            float next_real = (real_square - imag_square) + cr;
            float next_imag = (real_imag + imag_real) + ci;
            if (!finite_f32(next_real) || !finite_f32(next_imag)) return -1;
            real = next_real;
            imag = next_imag;
        }
        computed[2 * point] = real;
        computed[2 * point + 1] = imag;
    }
    for (usz component = 0; component < 2 * count; ++component)
        put_f32(computed[component], output, component * 4);
    return (long)needed;
}
