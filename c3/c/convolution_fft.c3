module convolution_fft;

extern fn double cos(double value);
extern fn double sin(double value);

const usz MAX_SIGNAL_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_SIGNAL_LENGTH + 1;
const usz MAX_FFT_LENGTH = 2 * MAX_SIGNAL_LENGTH;
const double PI = 3.14159265358979323846264338327950288;

fn void write_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn void fft(double* real, double* imag, usz n, bool inverse) {
    usz reverse = 0;
    for (usz position = 1; position < n; position++) {
        usz bit = n >> 1;
        while ((reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) {
            double temporary = real[position]; real[position] = real[reverse]; real[reverse] = temporary;
            temporary = imag[position]; imag[position] = imag[reverse]; imag[reverse] = temporary;
        }
    }
    for (usz block = 2; block <= n; block *= 2) {
        double direction = inverse ? -1.0 : 1.0;
        double angle = -2.0 * PI / (double)block * direction;
        double step_real = cos(angle), step_imag = sin(angle);
        for (usz start = 0; start < n; start += block) {
            double weight_real = 1.0, weight_imag = 0.0;
            for (usz offset = 0; offset < block / 2; offset++) {
                usz first = start + offset, second = first + block / 2;
                double product_real = weight_real * real[second] - weight_imag * imag[second];
                double product_imag = weight_real * imag[second] + weight_imag * real[second];
                double first_real = real[first], first_imag = imag[first];
                real[first] = first_real + product_real; imag[first] = first_imag + product_imag;
                real[second] = first_real - product_real; imag[second] = first_imag - product_imag;
                double next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real; weight_real = next_real;
            }
        }
    }
    if (inverse) for (usz index = 0; index < n; index++) { real[index] /= (double)n; imag[index] /= (double)n; }
}

fn long convolution_fft(long* input, usz length, char* output, usz capacity) @export("convolution_fft") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long raw_a = input[0], raw_b = input[1];
    if (raw_a < 1 || raw_a > 64 || raw_b < 1 || raw_b > 64) return -1;
    usz a_count = (usz)raw_a, b_count = (usz)raw_b;
    if (length != 2 + a_count + b_count) return -1;
    for (usz index = 0; index < a_count + b_count; index++) if (input[index + 2] < -64 || input[index + 2] > 64) return -1;
    usz result_count = a_count + b_count - 1, byte_count = result_count * 16;
    if (output == null || capacity < byte_count) return -2;
    usz fft_length = 1;
    while (fft_length < result_count) fft_length *= 2;
    double[128] a_real, a_imag, b_real, b_imag, product_real, product_imag;
    for (usz index = 0; index < fft_length; index++) {
        a_real[index] = 0.0; a_imag[index] = 0.0;
        b_real[index] = 0.0; b_imag[index] = 0.0;
        product_real[index] = 0.0; product_imag[index] = 0.0;
    }
    for (usz index = 0; index < a_count; index++) a_real[index] = (double)input[index + 2] / 16.0;
    for (usz index = 0; index < b_count; index++) b_real[index] = (double)input[a_count + index + 2] / 16.0;
    fft(&a_real[0], &a_imag[0], fft_length, false); fft(&b_real[0], &b_imag[0], fft_length, false);
    for (usz index = 0; index < fft_length; index++) {
        product_real[index] = a_real[index] * b_real[index] - a_imag[index] * b_imag[index];
        product_imag[index] = a_real[index] * b_imag[index] + a_imag[index] * b_real[index];
    }
    fft(&product_real[0], &product_imag[0], fft_length, true);
    for (usz index = 0; index < result_count; index++) {
        write_f64_le(product_real[index], output, index * 16);
        write_f64_le(product_imag[index], output, index * 16 + 8);
    }
    return (long)byte_count;
}
