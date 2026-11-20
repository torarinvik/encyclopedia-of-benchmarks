module direct_discrete_fourier_transform;

extern fn double cos(double value);
extern fn double sin(double value);

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 130;
const double TAU = 6.283185307179586476925286766559;

fn long direct_discrete_fourier_transform(double* input, usz input_length, double* output,
                                           usz output_capacity)
    @export("direct_discrete_fourier_transform") {
    if (input == null || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1L;
    for (usz i = 0; i < input_length; i++) {
        if (input[i] != input[i] || input[i] > 1.7976931348623157e308
            || input[i] < -1.7976931348623157e308) return -1L;
    }
    double n_value = input[0];
    if (n_value < 1.0 || n_value > (double)MAX_N) return -1L;
    usz n = (usz)n_value;
    if ((double)n != n_value || input_length != 1 + 2 * n) return -1L;
    for (usz i = 0; i < 2 * n; i++)
        if (input[i + 1] < -8.0 || input[i + 1] > 8.0) return -1L;

    usz needed = 2 * n;
    if (output == null || output_capacity < needed) return -2L;
    for (usz k = 0; k < n; k++) {
        double real_sum = 0.0;
        double imag_sum = 0.0;
        for (usz j = 0; j < n; j++) {
            double angle = -TAU * (double)j * (double)k / (double)n;
            double cosine = cos(angle), sine = sin(angle);
            double sample_real = input[1 + 2 * j], sample_imag = input[2 + 2 * j];
            real_sum += sample_real * cosine + sample_imag * sine;
            imag_sum += sample_imag * cosine - sample_real * sine;
        }
        output[2 * k] = real_sum;
        output[2 * k + 1] = imag_sum;
    }
    (long)needed
}

