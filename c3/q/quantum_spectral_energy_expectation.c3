module quantum_spectral_energy_expectation;

extern fn double cos(double value);
extern fn double sin(double value);

const long MAX_N = 32;
const long SCALE = 256;
const double INVALID_RESULT = -1.0e300;
const double TAU = 6.283185307179586476925286766559005768;

fn void fft(double[32]* real, double[32]* imag, usz n, bool inverse) {
    usz j = 0;
    for (usz i = 1; i < n; i++) {
        usz bit = n >> 1;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) {
            double temporary = real[i]; real[i] = real[j]; real[j] = temporary;
            temporary = imag[i]; imag[i] = imag[j]; imag[j] = temporary;
        }
    }
    for (usz width = 2; width <= n; width <<= 1) {
        double angle = (inverse ? 1.0 : -1.0) * TAU / (double)width;
        double step_real = cos(angle), step_imag = sin(angle);
        usz half = width >> 1;
        for (usz start = 0; start < n; start += width) {
            double twiddle_real = 1.0, twiddle_imag = 0.0;
            for (usz offset = 0; offset < half; offset++) {
                usz even = start + offset, odd = even + half;
                double odd_real = real[odd] * twiddle_real - imag[odd] * twiddle_imag;
                double odd_imag = real[odd] * twiddle_imag + imag[odd] * twiddle_real;
                real[odd] = real[even] - odd_real;
                imag[odd] = imag[even] - odd_imag;
                real[even] += odd_real;
                imag[even] += odd_imag;
                double next_real = twiddle_real * step_real - twiddle_imag * step_imag;
                twiddle_imag = twiddle_real * step_imag + twiddle_imag * step_real;
                twiddle_real = next_real;
            }
        }
    }
    if (inverse) for (usz i = 0; i < n; i++) { real[i] /= (double)n; imag[i] /= (double)n; }
}

fn double quantum_spectral_energy_expectation(long* values, usz length)
        @export("quantum_spectral_energy_expectation") {
    if (values == null || length < 1 || length > 98) return INVALID_RESULT;
    long n_value = values[0];
    if (n_value < 2 || n_value > MAX_N || (n_value & (n_value - 1)) != 0) return INVALID_RESULT;
    usz n = (usz)n_value;
    if (length != 1 + 3 * n) return INVALID_RESULT;
    long norm = 0;
    for (usz i = 0; i < n; i++) {
        long potential = values[1 + i], real_q = values[1 + n + i], imag_q = values[1 + 2 * n + i];
        if (potential < -2048 || potential > 2048 || real_q < -2048 || real_q > 2048 ||
            imag_q < -2048 || imag_q > 2048) return INVALID_RESULT;
        norm += real_q * real_q + imag_q * imag_q;
    }
    if (norm != SCALE * SCALE * n_value) return INVALID_RESULT;
    double[32] real = {}, imag = {};
    for (usz i = 0; i < n; i++) {
        real[i] = (double)values[1 + n + i] / SCALE;
        imag[i] = (double)values[1 + 2 * n + i] / SCALE;
    }
    fft(&real, &imag, n, false);
    for (usz i = 0; i < n; i++) {
        long frequency = i <= n / 2 ? (long)i : (long)i - n_value;
        double wave_number = TAU * (double)frequency;
        double multiplier = 0.5 * wave_number * wave_number;
        real[i] *= multiplier;
        imag[i] *= multiplier;
    }
    fft(&real, &imag, n, true);
    double total = 0.0;
    for (usz i = 0; i < n; i++) {
        double psi_real = (double)values[1 + n + i] / SCALE;
        double psi_imag = (double)values[1 + 2 * n + i] / SCALE;
        double potential = (double)values[1 + i] / SCALE;
        total += psi_real * (real[i] + potential * psi_real) +
                 psi_imag * (imag[i] + potential * psi_imag);
    }
    return total / (double)n;
}
