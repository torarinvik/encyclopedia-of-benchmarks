// Based on Don Cross <dcross@intersrv.com>'s public-domain fft_float (intersrv.com/~dcross/fft.html).
// Modified for the bounded float64-slice ABI; binary32 work-array semantics retained.
module mibench_telecomm_fft;
extern fn double sin(double value);
extern fn double cos(double value);
extern fn double trunc(double value);

fn void transform(float* real, float* imag, usz n, bool inverse) {
    usz bits = 0;
    for (usz v = n; v > 1; v >>= 1) bits += 1;
    for (usz i = 0; i < n; i += 1) {
        usz source = i, reverse = 0;
        for (usz b = 0; b < bits; b += 1) { reverse = (reverse << 1) | (source & 1); source >>= 1; }
        if (i < reverse) { float t = real[i]; real[i] = real[reverse]; real[reverse] = t; t = imag[i]; imag[i] = imag[reverse]; imag[reverse] = t; }
    }
    double angle_num = (inverse ? -2.0 : 2.0) * 3.14159265358979323846;
    usz block_end = 1;
    for (usz block = 2; block <= n; block <<= 1) {
        double delta = angle_num / (double)block;
        double sm2 = sin(-2.0 * delta), sm1 = sin(-delta);
        double cm2 = cos(-2.0 * delta), cm1 = cos(-delta), w = 2.0 * cm1;
        for (usz start = 0; start < n; start += block) {
            double ar2 = cm2, ar1 = cm1, ai2 = sm2, ai1 = sm1;
            for (usz offset = 0; offset < block_end; offset += 1) {
                double ar0 = w * ar1 - ar2; ar2 = ar1; ar1 = ar0;
                double ai0 = w * ai1 - ai2; ai2 = ai1; ai1 = ai0;
                usz first = start + offset, second = first + block_end;
                double tr = ar0 * (double)real[second] - ai0 * (double)imag[second];
                double ti = ar0 * (double)imag[second] + ai0 * (double)real[second];
                real[second] = (float)((double)real[first] - tr); imag[second] = (float)((double)imag[first] - ti);
                real[first] = (float)((double)real[first] + tr); imag[first] = (float)((double)imag[first] + ti);
            }
        }
        block_end = block;
    }
    if (inverse) for (usz i = 0; i < n; i += 1) { real[i] = (float)((double)real[i] / (double)n); imag[i] = (float)((double)imag[i] / (double)n); }
}

fn long mibench_telecomm_fft(double* input, usz length, double* output, usz capacity) @export("mibench_telecomm_fft") {
    if (input == null || length < 6 || length > 34) return -1;
    double nd = input[0], inv = input[1];
    if (nd != nd || inv != inv || trunc(nd) != nd || trunc(inv) != inv || nd < 2 || nd > 16 || (inv != 0 && inv != 1)) return -1;
    usz n = (usz)nd;
    if ((n & (n - 1)) != 0 || length != 2 + 2 * n) return -1;
    for (usz i = 2; i < length; i += 1) if (!(input[i] >= -8.0 && input[i] <= 8.0)) return -1;
    usz required = 2 * n;
    if (output == null || capacity < required) return -2;
    float real[16], imag[16];
    for (usz i = 0; i < n; i += 1) { real[i] = (float)input[2 + i]; imag[i] = (float)input[2 + n + i]; }
    transform(&real[0], &imag[0], n, inv != 0);
    double staged[32];
    for (usz i = 0; i < n; i += 1) { staged[2 * i] = (double)real[i]; staged[2 * i + 1] = (double)imag[i]; }
    for (usz i = 0; i < required; i += 1) output[i] = staged[i];
    return (long)required;
}
