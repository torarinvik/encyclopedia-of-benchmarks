module perlin_noise;

const usz MAX_DIMENSION = 8;
const usz MAX_INPUT_ELEMENTS = 5;
const usz MAX_PARSEABLE_INPUT_ELEMENTS = 6;
const usz MAX_OUTPUT_ELEMENTS = MAX_DIMENSION * MAX_DIMENSION;
const ulong JAVA_MULTIPLIER = 0x5DEECE66D;
const ulong JAVA_ADDEND = 0xB;
const ulong JAVA_MASK = (1UL << 48) - 1;

fn float rounded_add(float a, float b) { return a + b; }
fn float rounded_sub(float a, float b) { return a - b; }
fn float rounded_mul(float a, float b) { return a * b; }
fn float rounded_div(float a, float b) { return a / b; }

fn uint java_next(ulong* state, uint bits) {
    *state = (*state *% JAVA_MULTIPLIER +% JAVA_ADDEND) & JAVA_MASK;
    return (uint)(*state >> (48 - bits));
}

fn float interpolate(float a, float b, float alpha) {
    float one_minus_alpha = rounded_sub(1.0f, alpha);
    float left = rounded_mul(a, one_minus_alpha);
    float right = rounded_mul(alpha, b);
    return rounded_add(left, right);
}

fn bool exact_integer(double value, double minimum, double maximum) {
    return value >= minimum && value <= maximum && (double)(long)value == value;
}

long perlin_noise(double* input, usz length, double* output, usz output_capacity) @export("perlin_noise") {
    if (input == null || length < 4 || length > MAX_PARSEABLE_INPUT_ELEMENTS) return -1;
    if (length != MAX_INPUT_ELEMENTS) return -1;
    if (!exact_integer(input[0], 1.0, 8.0) || !exact_integer(input[1], 1.0, 8.0) ||
        !exact_integer(input[2], 1.0, 4.0) || !exact_integer(input[4], 0.0, 2147483647.0) ||
        (input[3] != 0.5 && input[3] != 0.75 && input[3] != 1.0)) return -1;
    int width = (int)input[0], height = (int)input[1], octave_count = (int)input[2];
    ulong seed = (ulong)input[4];
    usz count = (usz)(width * height);
    float[MAX_OUTPUT_ELEMENTS] base;
    float[4 * MAX_OUTPUT_ELEMENTS] layers;
    float[MAX_OUTPUT_ELEMENTS] result;
    ulong state = (seed ^ JAVA_MULTIPLIER) & JAVA_MASK;
    for (int x = 0; x < width; x++) for (int y = 0; y < height; y++) {
        base[x * height + y] = rounded_div((float)java_next(&state, 24), 16777216.0f);
    }
    for (int octave = 0; octave < octave_count; octave++) {
        int period = 1 << octave;
        float frequency = rounded_div(1.0f, (float)period);
        usz offset = (usz)octave * MAX_OUTPUT_ELEMENTS;
        for (int x = 0; x < width; x++) {
            int x0 = (x / period) * period, x1 = (x0 + period) % width;
            float horizontal = rounded_mul((float)(x - x0), frequency);
            for (int y = 0; y < height; y++) {
                int y0 = (y / period) * period, y1 = (y0 + period) % height;
                float vertical = rounded_mul((float)(y - y0), frequency);
                float top = interpolate(base[x0 * height + y0], base[x1 * height + y0], horizontal);
                float bottom = interpolate(base[x0 * height + y1], base[x1 * height + y1], horizontal);
                layers[offset + (usz)(x * height + y)] = interpolate(top, bottom, vertical);
            }
        }
    }
    float persistence = (float)input[3], amplitude = 1.0f, total_amplitude = 0.0f;
    for (int octave = octave_count - 1; octave >= 0; octave--) {
        amplitude = rounded_mul(amplitude, persistence);
        total_amplitude = rounded_add(total_amplitude, amplitude);
        usz offset = (usz)octave * MAX_OUTPUT_ELEMENTS;
        for (usz i = 0; i < count; i++) result[i] = rounded_add(result[i], rounded_mul(layers[offset + i], amplitude));
    }
    float inverse_total = rounded_div(1.0f, total_amplitude);
    for (usz i = 0; i < count; i++) result[i] = rounded_mul(result[i], inverse_total);
    if (output == null || output_capacity < count) return -2;
    for (usz i = 0; i < count; i++) output[i] = (double)result[i];
    return (long)count;
}
