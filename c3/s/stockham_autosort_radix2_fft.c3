module stockham_autosort_radix2_fft;

extern fn double cos(double value);
extern fn double sin(double value);

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 130;
const usz MAX_SCALARS = 128;
const double TAU = 6.283185307179586476925286766559;

fn void stockham_stage(double* source, double* destination, usz n, usz stride) {
    for (usz j = 0; j < n / 2; j++) {
        usz column = j % stride;
        usz group = j / stride;
        usz base = group * 2 * stride + column;
        double angle = -TAU * (double)column / (double)(2 * stride);
        double cosine = cos(angle), sine = sin(angle);
        usz left = 2 * j, right = 2 * (j + n / 2);
        double product_real = cosine * source[right] - sine * source[right + 1];
        double product_imag = cosine * source[right + 1] + sine * source[right];
        double first_real = source[left], first_imag = source[left + 1];
        usz out_left = 2 * base, out_right = 2 * (base + stride);
        destination[out_left] = first_real + product_real;
        destination[out_left + 1] = first_imag + product_imag;
        destination[out_right] = first_real - product_real;
        destination[out_right + 1] = first_imag - product_imag;
    }
}

fn long stockham_autosort_radix2_fft(double* input, usz input_length, double* output,
                                      usz output_capacity) @export("stockham_autosort_radix2_fft") {
    if (input == null || input_length < 3 || input_length > MAX_INPUT_LENGTH) return -1L;
    for (usz i = 0; i < input_length; i++) {
        if (input[i] != input[i] || input[i] > 1.7976931348623157e308
            || input[i] < -1.7976931348623157e308) return -1L;
    }
    double n_value = input[0];
    if (n_value < 1.0 || n_value > (double)MAX_N) return -1L;
    usz n = (usz)n_value;
    if ((double)n != n_value) return -1L;
    if ((n & (n - 1)) != 0 || input_length != 1 + 2 * n) return -1L;
    for (usz i = 0; i < 2 * n; i++)
        if (input[i + 1] < -8.0 || input[i + 1] > 8.0) return -1L;

    double[MAX_SCALARS] first = zeroed;
    double[MAX_SCALARS] second = zeroed;
    for (usz i = 0; i < 2 * n; i++) first[i] = input[i + 1];
    double* source = &first[0];
    double* destination = &second[0];
    for (usz stride = 1; stride < n; stride *= 2) {
        stockham_stage(source, destination, n, stride);
        double* temporary = source;
        source = destination;
        destination = temporary;
    }

    usz needed = 2 * n;
    if (output == null || output_capacity < needed) return -2L;
    for (usz i = 0; i < needed; i++) output[i] = source[i];
    (long)needed
}
