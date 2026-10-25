module freebench_pifft;

const int FFT_SIZE = 8;
const long BASE = 1000;
const long SCALE = 1000000;

fn void fft_transform(double* real, double* imag, bool inverse) {
    int j = 0;
    for (int i = 1; i < FFT_SIZE; i++) {
        int bit = FFT_SIZE >> 1;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) {
            double temp = real[i]; real[i] = real[j]; real[j] = temp;
            temp = imag[i]; imag[i] = imag[j]; imag[j] = temp;
        }
    }
    for (int length = 2; length <= FFT_SIZE; length <<= 1) {
        double root_real;
        double root_imag;
        if (length == 2) { root_real = -1.0; root_imag = 0.0; }
        else if (length == 4) { root_real = 0.0; root_imag = inverse ? 1.0 : -1.0; }
        else { root_real = 0.70710678118654752440; root_imag = inverse ? 0.70710678118654752440 : -0.70710678118654752440; }
        int half = length >> 1;
        for (int start = 0; start < FFT_SIZE; start += length) {
            double twiddle_real = 1.0;
            double twiddle_imag = 0.0;
            for (int offset = 0; offset < half; offset++) {
                int even = start + offset;
                int odd = even + half;
                double odd_real = real[odd] * twiddle_real - imag[odd] * twiddle_imag;
                double odd_imag = real[odd] * twiddle_imag + imag[odd] * twiddle_real;
                double even_real = real[even];
                double even_imag = imag[even];
                real[even] = even_real + odd_real;
                imag[even] = even_imag + odd_imag;
                real[odd] = even_real - odd_real;
                imag[odd] = even_imag - odd_imag;
                double next_real = twiddle_real * root_real - twiddle_imag * root_imag;
                twiddle_imag = twiddle_real * root_imag + twiddle_imag * root_real;
                twiddle_real = next_real;
            }
        }
    }
    if (inverse) for (int i = 0; i < FFT_SIZE; i++) { real[i] /= FFT_SIZE; imag[i] /= FFT_SIZE; }
}

fn long fft_multiply_fixed(long left, long right) {
    int sign = 1;
    if (left < 0) { sign = -sign; left = -left; }
    if (right < 0) { sign = -sign; right = -right; }
    double[FFT_SIZE] left_real = {};
    double[FFT_SIZE] left_imag = {};
    double[FFT_SIZE] right_real = {};
    double[FFT_SIZE] right_imag = {};
    for (int i = 0; i < 3; i++) {
        left_real[i] = (double)(left % BASE);
        right_real[i] = (double)(right % BASE);
        left /= BASE;
        right /= BASE;
    }
    fft_transform(&left_real[0], &left_imag[0], false);
    fft_transform(&right_real[0], &right_imag[0], false);
    for (int i = 0; i < FFT_SIZE; i++) {
        double product_real = left_real[i] * right_real[i] - left_imag[i] * right_imag[i];
        double product_imag = left_real[i] * right_imag[i] + left_imag[i] * right_real[i];
        left_real[i] = product_real;
        left_imag[i] = product_imag;
    }
    fft_transform(&left_real[0], &left_imag[0], true);
    long product = 0;
    long place = 1;
    for (int i = 0; i < 5; i++) {
        long coefficient = (long)(left_real[i] + 0.5);
        product += coefficient * place;
        place *= BASE;
    }
    long rounded = (product + SCALE / 2) / SCALE;
    return sign < 0 ? -rounded : rounded;
}

fn long fixed_sqrt(long value) {
    if (value <= 0) return 0;
    long radicand = value * SCALE;
    long root = radicand;
    while (true) {
        long next = (root + radicand / root) / 2;
        if (next >= root) break;
        root = next;
    }
    long lower_error = radicand - root * root;
    long upper_error = (root + 1) * (root + 1) - radicand;
    return upper_error < lower_error ? root + 1 : root;
}

fn long fixed_half(long value) { return value < 0 ? -((-value) / 2) : value / 2; }

fn long fixed_divide(long numerator, long denominator) {
    if (denominator <= 0) return 0;
    long scaled = numerator * SCALE;
    if (scaled < 0) return -((-scaled + denominator / 2) / denominator);
    return (scaled + denominator / 2) / denominator;
}

fn long freebench_pifft(long nfft) @export("freebench_pifft") {
    if (nfft != FFT_SIZE) return -1;
    long c = fixed_sqrt(125000);
    long a = SCALE + 3 * c;
    long b = fixed_sqrt(a);
    long e = b - 625000;
    b *= 2;
    c = e - c;
    a += e;
    long npow = 4;
    for (int iteration = 0; iteration < 8; iteration++) {
        npow *= 2;
        e = fixed_half(a + b);
        b = fixed_sqrt(fft_multiply_fixed(a, b));
        e -= b;
        b *= 2;
        c -= e;
        a = e + b;
        if (e >= -1 && e <= 1) break;
    }
    e = fixed_half(e);
    e = fft_multiply_fixed(e, e);
    a += b;
    long numerator = fft_multiply_fixed(a, a) - e - fixed_half(e);
    long denominator = fft_multiply_fixed(a, c) - e;
    long pi = fixed_divide(numerator, denominator);
    pi = (pi + npow / 2) / npow;
    return (pi + 500) / 1000;
}
