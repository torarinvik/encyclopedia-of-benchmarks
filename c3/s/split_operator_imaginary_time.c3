module split_operator_imaginary_time;

extern fn double trunc(double value);
extern fn double sqrt(double value);
extern fn double cos(double value);
extern fn double sin(double value);

const usz MAX_N = 64;
const usz MAX_STEPS = 8;
const usz MAX_INPUT_LENGTH = 2 + 4 * MAX_N;
const double TAU = 6.28318530717958647692528676655900577;

fn bool bounded_integer(double value, double minimum, double maximum) {
    return value == value && value >= minimum && value <= maximum && trunc(value) == value;
}

fn void fft(double* real, double* imag, usz n, bool inverse) {
    usz reverse = 0;
    for (usz position = 1; position < n; position += 1) {
        usz bit = n >> 1;
        while (bit != 0 && (reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) {
            double temporary = real[position]; real[position] = real[reverse]; real[reverse] = temporary;
            temporary = imag[position]; imag[position] = imag[reverse]; imag[reverse] = temporary;
        }
    }
    for (usz block = 2; block <= n; block *= 2) {
        double direction = 1.0;
        if (!inverse) direction = -1.0;
        double angle = direction * TAU / (double)block;
        double step_real = cos(angle), step_imag = sin(angle);
        for (usz start = 0; start < n; start += block) {
            double weight_real = 1.0, weight_imag = 0.0;
            for (usz offset = 0; offset < block / 2; offset += 1) {
                usz first = start + offset, second = first + block / 2;
                double product_real = weight_real * real[second] - weight_imag * imag[second];
                double product_imag = weight_real * imag[second] + weight_imag * real[second];
                double first_real = real[first], first_imag = imag[first];
                real[first] = first_real + product_real; imag[first] = first_imag + product_imag;
                real[second] = first_real - product_real; imag[second] = first_imag - product_imag;
                double next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real;
                weight_real = next_real;
            }
        }
    }
    if (inverse) for (usz i = 0; i < n; i += 1) { real[i] /= (double)n; imag[i] /= (double)n; }
}

fn void normalize(double* real, double* imag, usz n) {
    double norm_squared = 0.0;
    for (usz i = 0; i < n; i += 1) norm_squared += real[i] * real[i] + imag[i] * imag[i];
    double norm = sqrt(norm_squared);
    for (usz i = 0; i < n; i += 1) { real[i] /= norm; imag[i] /= norm; }
}

fn long split_operator_imaginary_time(double* input, usz length, double* output, usz capacity)
    @export("split_operator_imaginary_time") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (!bounded_integer(input[0], 2.0, (double)MAX_N) || !bounded_integer(input[1], 0.0, (double)MAX_STEPS)) return -1;
    usz n = (usz)input[0], steps = (usz)input[1];
    if ((n & (n - 1)) != 0 || length != 2 + 4 * n) return -1;
    usz momentum_start = 2 + n, state_start = 2 + 2 * n;
    double norm_squared = 0.0;
    for (usz i = 0; i < n; i += 1) {
        double position = input[2 + i], momentum = input[momentum_start + i];
        double real_value = input[state_start + 2 * i], imag_value = input[state_start + 2 * i + 1];
        if (position != position || position < 0.25 || position > 1.0
                || momentum != momentum || momentum < 0.25 || momentum > 1.0
                || real_value != real_value || real_value < -1.0 || real_value > 1.0
                || imag_value != imag_value || imag_value < -1.0 || imag_value > 1.0) return -1;
        norm_squared += real_value * real_value + imag_value * imag_value;
    }
    if (!(norm_squared > 0.0)) return -1;
    usz output_count = 2 * n;
    if (output == null || capacity < output_count) return -2;
    double[MAX_N] real, imag;
    for (usz i = 0; i < n; i += 1) { real[i] = input[state_start + 2 * i]; imag[i] = input[state_start + 2 * i + 1]; }
    normalize(&real[0], &imag[0], n);
    for (usz step = 0; step < steps; step += 1) {
        for (usz i = 0; i < n; i += 1) { real[i] *= input[2 + i]; imag[i] *= input[2 + i]; }
        fft(&real[0], &imag[0], n, false);
        for (usz i = 0; i < n; i += 1) { real[i] *= input[momentum_start + i]; imag[i] *= input[momentum_start + i]; }
        fft(&real[0], &imag[0], n, true);
        for (usz i = 0; i < n; i += 1) { real[i] *= input[2 + i]; imag[i] *= input[2 + i]; }
        normalize(&real[0], &imag[0], n);
    }
    for (usz i = 0; i < n; i += 1) { output[2 * i] = real[i]; output[2 * i + 1] = imag[i]; }
    return (long)output_count;
}
