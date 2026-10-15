module fast_fourier_transform;

extern fn double cos(double value);
extern fn double sin(double value);

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long quantize(double value) {
    double scaled = value * 1000000.0;
    return (long)(scaled >= 0.0 ? scaled + 0.5 : scaled - 0.5);
}

fn void transform(double* real, double* imag, usz n) {
    usz reverse = 0;
    for (usz position = 1; position < n; position += 1) {
        usz bit = n >> 1;
        while ((reverse & bit) != 0) { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if (position < reverse) {
            double temporary = real[position]; real[position] = real[reverse]; real[reverse] = temporary;
            temporary = imag[position]; imag[position] = imag[reverse]; imag[reverse] = temporary;
        }
    }
    for (usz block = 2; block <= n; block *= 2) {
        double angle = 6.283185307179586476925286766559 / (double)block;
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
}

fn long fast_fourier_transform(long* values, usz length, char* output, usz capacity) @export("fast_fourier_transform") {
    if (values == null || length < 2 || length > 65) return -1;
    long raw_n = values[0];
    if (raw_n < 1 || raw_n > 64 || (raw_n & (raw_n - 1)) != 0 || length != (usz)raw_n + 1) return -1;
    usz n = (usz)raw_n;
    for (usz index = 0; index < n; index += 1) if (values[index + 1] < -1000 || values[index + 1] > 1000) return -1;
    usz byte_count = 16 * n;
    if (output == null || capacity < byte_count) return -2;
    double[64] real, imag;
    for (usz index = 0; index < n; index += 1) { real[index] = (double)values[index + 1]; imag[index] = 0.0; }
    transform(&real[0], &imag[0], n);
    for (usz index = 0; index < n; index += 1) {
        store_i64_le(output, 16 * index, quantize(real[index]));
        store_i64_le(output, 16 * index + 8, quantize(imag[index]));
    }
    return (long)byte_count;
}
