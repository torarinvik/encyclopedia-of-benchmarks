module rader_fft;
import "math";

const double MAX_COMPONENT = 100.0;
const double PI_VALUE = 3.14159265358979323846264338327950288;

fn void fft8(double* real, double* imag, bool inverse) {
    usz[8] reversed = {0, 4, 2, 6, 1, 5, 3, 7};
    for (usz i = 0; i < 8; i++) {
        usz j = reversed[i];
        if (i < j) {
            double t = real[i]; real[i] = real[j]; real[j] = t;
            t = imag[i]; imag[i] = imag[j]; imag[j] = t;
        }
    }
    for (usz stage = 1; stage <= 3; stage++) {
        usz block = (usz)1 << stage;
        usz half = block / 2;
        for (usz start = 0; start < 8; start += block) {
            for (usz j = 0; j < half; j++) {
                double sign = inverse ? 1.0 : -1.0;
                double angle = sign * 2.0 * PI_VALUE * (double)j / (double)block;
                double wr = math.cos(angle), wi = math.sin(angle);
                usz even = start + j, odd = even + half;
                double ur = real[even], ui = imag[even];
                double vr = real[odd] * wr - imag[odd] * wi;
                double vi = real[odd] * wi + imag[odd] * wr;
                real[even] = ur + vr; imag[even] = ui + vi;
                real[odd] = ur - vr; imag[odd] = ui - vi;
            }
        }
    }
    if (inverse) for (usz i = 0; i < 8; i++) { real[i] /= 8.0; imag[i] /= 8.0; }
}

fn long rader_fft(double* input, usz input_length, double* output, usz output_capacity)
    @export("rader_fft") {
    usz[4] permutation = {1, 2, 4, 3};
    usz[4] kernel_power = {1, 3, 4, 2};
    if (input == null || input_length != 10) return -1;
    for (usz i = 0; i < 10; i++)
        if (input[i] != input[i] || input[i] < -MAX_COMPONENT || input[i] > MAX_COMPONENT) return -1;
    if (output == null || output_capacity < 10) return -2;

    double[8] ar = {0}, ai = {0}, br = {0}, bi = {0};
    for (usz i = 0; i < 4; i++) {
        ar[i] = input[2 * permutation[i]]; ai[i] = input[2 * permutation[i] + 1];
        double angle = -2.0 * PI_VALUE * (double)kernel_power[i] / 5.0;
        br[i] = math.cos(angle); bi[i] = math.sin(angle);
    }
    fft8(&ar[0], &ai[0], false); fft8(&br[0], &bi[0], false);
    for (usz i = 0; i < 8; i++) {
        double product_real = ar[i] * br[i] - ai[i] * bi[i];
        double product_imag = ar[i] * bi[i] + ai[i] * br[i];
        ar[i] = product_real; ai[i] = product_imag;
    }
    fft8(&ar[0], &ai[0], true);

    double[10] result = {0};
    for (usz n = 0; n < 5; n++) { result[0] += input[2 * n]; result[1] += input[2 * n + 1]; }
    for (usz k = 1; k < 5; k++) { result[2 * k] = input[0]; result[2 * k + 1] = input[1]; }
    for (usz i = 0; i < 4; i++) {
        usz target = kernel_power[i];
        result[2 * target] += ar[i] + ar[i + 4];
        result[2 * target + 1] += ai[i] + ai[i + 4];
    }
    for (usz i = 0; i < 10; i++) output[i] = result[i];
    return 10;
}
