module rgb_cmyk_conversion;

extern fn double floor(double value);
const usz OUTPUT_LENGTH = 4;

fn long round_ties_to_even(double value) {
    double lower = floor(value);
    double fraction = value - lower;
    long base = (long)lower;
    if (fraction < 0.5) return base;
    if (fraction > 0.5) return base + 1;
    return (base & 1) == 0 ? base : base + 1;
}

fn long rgb_cmyk_conversion(long* input, usz length, char* output, usz capacity) @export("rgb_cmyk_conversion") {
    if (input == null || length != 3) return -1;
    for (usz i = 0; i < 3; i++) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == null || capacity < OUTPUT_LENGTH) return -2;
    double red = (double)input[0] / 255.0;
    double green = (double)input[1] / 255.0;
    double blue = (double)input[2] / 255.0;
    double maximum = red;
    if (green > maximum) maximum = green;
    if (blue > maximum) maximum = blue;
    double key = 1.0 - maximum;
    if (key == 1.0) {
        output[0] = 0; output[1] = 0; output[2] = 0; output[3] = 100;
        return OUTPUT_LENGTH;
    }
    double denominator = 1.0 - key;
    output[0] = (char)round_ties_to_even(100.0 * (1.0 - red - key) / denominator);
    output[1] = (char)round_ties_to_even(100.0 * (1.0 - green - key) / denominator);
    output[2] = (char)round_ties_to_even(100.0 * (1.0 - blue - key) / denominator);
    output[3] = (char)round_ties_to_even(100.0 * key);
    return OUTPUT_LENGTH;
}
