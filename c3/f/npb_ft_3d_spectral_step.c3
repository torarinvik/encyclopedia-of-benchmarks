module npb_ft_3d_spectral_step;

extern fn double trunc(double value);
extern fn double cos(double value);
extern fn double sin(double value);
extern fn double exp(double value);

const usz MAX_SIDE = 4;
const usz MAX_POINTS = 64;
const usz MAX_STEPS = 6;
const usz CHECKSUM_TERMS = 64;
const double TAU = 6.28318530717958647692528676655900577;
const double ALPHA = 0.000001;

fn bool bounded_integer(double value, double low, double high) {
    return value == value && value >= low && value <= high && trunc(value) == value;
}

fn void fft_line(double* real, double* imag, usz n, bool inverse) {
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

fn void axis_transform(double* real, double* imag, usz n, usz axis, bool inverse) {
    double[4] line_real, line_imag;
    for (usz a = 0; a < n; a += 1) for (usz b = 0; b < n; b += 1) {
        for (usz p = 0; p < n; p += 1) {
            usz x = a, y = b, z = p;
            if (axis == 0) { x = p; y = a; z = b; }
            else if (axis == 1) { x = a; y = p; z = b; }
            usz index = (x * n + y) * n + z;
            line_real[p] = real[index]; line_imag[p] = imag[index];
        }
        fft_line(&line_real[0], &line_imag[0], n, inverse);
        for (usz p = 0; p < n; p += 1) {
            usz x = a, y = b, z = p;
            if (axis == 0) { x = p; y = a; z = b; }
            else if (axis == 1) { x = a; y = p; z = b; }
            usz index = (x * n + y) * n + z;
            real[index] = line_real[p]; imag[index] = line_imag[p];
        }
    }
}

fn void transform3d(double* real, double* imag, usz n, bool inverse) {
    axis_transform(real, imag, n, 2, inverse);
    axis_transform(real, imag, n, 1, inverse);
    axis_transform(real, imag, n, 0, inverse);
}

fn int signed_frequency(usz index, usz n) {
    if (index <= n / 2) return (int)index;
    return (int)index - (int)n;
}

fn long npb_ft_3d_spectral_step(double* input, usz length, double* output, usz capacity)
    @export("npb_ft_3d_spectral_step") {
    if (input == null || length < 2 || length > 130) return -1;
    if (!bounded_integer(input[0], 2.0, 4.0) || !bounded_integer(input[1], 1.0, (double)MAX_STEPS)) return -1;
    usz n = (usz)input[0], steps = (usz)input[1];
    if ((n != 2 && n != 4) || length != 2 + 2 * n * n * n) return -1;
    usz volume = n * n * n, needed = 2 * steps;
    for (usz i = 2; i < length; i += 1) if (input[i] != input[i] || input[i] < -1.0 || input[i] > 1.0) return -1;
    if (output == null || capacity < needed) return -2;

    double[MAX_POINTS] spectrum_real, spectrum_imag, work_real, work_imag;
    for (usz i = 0; i < volume; i += 1) {
        spectrum_real[i] = input[2 + 2 * i]; spectrum_imag[i] = input[2 + 2 * i + 1];
    }
    transform3d(&spectrum_real[0], &spectrum_imag[0], n, false);
    for (usz step = 1; step <= steps; step += 1) {
        for (usz x = 0; x < n; x += 1) for (usz y = 0; y < n; y += 1) for (usz z = 0; z < n; z += 1) {
            usz index = (x * n + y) * n + z;
            int kx = signed_frequency(x, n), ky = signed_frequency(y, n), kz = signed_frequency(z, n);
            double radius_squared = (double)(kx * kx + ky * ky + kz * kz);
            double factor = exp(-39.47841760435743447533796399950460 * ALPHA * (double)step * radius_squared);
            work_real[index] = spectrum_real[index] * factor;
            work_imag[index] = spectrum_imag[index] * factor;
        }
        transform3d(&work_real[0], &work_imag[0], n, true);
        double sum_real = 0.0, sum_imag = 0.0;
        for (usz j = 1; j <= CHECKSUM_TERMS; j += 1) {
            usz x = (j - 1) % n, y = (3 * j - 1) % n, z = (5 * j - 1) % n;
            usz index = (x * n + y) * n + z;
            sum_real += work_real[index]; sum_imag += work_imag[index];
        }
        output[2 * (step - 1)] = sum_real / (double)volume;
        output[2 * (step - 1) + 1] = sum_imag / (double)volume;
    }
    return (long)needed;
}
