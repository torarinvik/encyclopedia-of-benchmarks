/*
 * Copyright (c) 2013 Argonne National Laboratory
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * Clean-room bounded adaptation of RSBench's Doppler-broadened microscopic lookup.
 */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define SCALE 1000000.0
#define MAX_WINDOWS 4
#define MAX_POLES 8
#define MAX_L 4
#define MAX_LENGTH 100

typedef struct { double re, im; } Cpx;

static Cpx add(Cpx a, Cpx b) { return (Cpx){a.re + b.re, a.im + b.im}; }
static Cpx sub(Cpx a, Cpx b) { return (Cpx){a.re - b.re, a.im - b.im}; }
static Cpx scale(Cpx a, double x) { return (Cpx){a.re * x, a.im * x}; }
static Cpx mul(Cpx a, Cpx b) { return (Cpx){a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re}; }
static Cpx divc(Cpx a, Cpx b) {
    const double denominator = b.re * b.re + b.im * b.im;
    return (Cpx){(a.re * b.re + a.im * b.im) / denominator,
                 (a.im * b.re - a.re * b.im) / denominator};
}
static Cpx exp_i12z(Cpx z) {
    const double magnitude = exp(-12.0 * z.im);
    const double angle = 12.0 * z.re;
    return (Cpx){magnitude * cos(angle), magnitude * sin(angle)};
}
static Cpx fast_nuclear_w(Cpx z) {
    static const double an[10] = {2.758402e-01,2.245740e-01,1.594149e-01,9.866577e-02,5.324414e-02,
        2.505215e-02,1.027747e-02,3.676164e-03,1.146494e-03,3.117570e-04};
    static const double signs[10] = {-1,1,-1,1,-1,1,-1,1,-1,1};
    static const double denominator_left[10] = {9.869604e+00,3.947842e+01,8.882644e+01,1.579137e+02,
        2.467401e+02,3.553058e+02,4.836106e+02,6.316547e+02,7.994380e+02,9.869604e+02};
    if (sqrt(z.re * z.re + z.im * z.im) < 6.0) {
        const Cpx e = exp_i12z(z);
        const Cpx one = {1.0, 0.0}, imaginary = {0.0, 1.0};
        Cpx w = divc(mul(imaginary, sub(one, e)), scale(z, 12.0));
        Cpx sum = {0.0, 0.0};
        for (int n = 0; n < 10; ++n) {
            const Cpx top = sub(scale(e, signs[n]), one);
            const Cpx z2 = mul(scale(z, 144.0), z);
            const Cpx bot = sub((Cpx){denominator_left[n], 0.0}, z2);
            sum = add(sum, scale(divc(top, bot), an[n]));
        }
        const Cpx prefactor = {0.0, 8.124330e+01};
        w = add(w, mul(mul(prefactor, z), sum));
        return w;
    }
    const double a = 0.512424224754768462984202823134979415014943561548661637413182;
    const double b = 0.275255128608410950901357962647054304017026259671664935783653;
    const double c = 0.051765358792987823963876628425793170829107067780337219430904;
    const double d = 2.724744871391589049098642037352945695982973740328335064216346;
    const Cpx z2 = mul(z, z);
    const Cpx left = divc((Cpx){a, 0.0}, sub(z2, (Cpx){b, 0.0}));
    const Cpx right = divc((Cpx){c, 0.0}, sub(z2, (Cpx){d, 0.0}));
    return mul(mul((Cpx){0.0, 1.0}, z), add(left, right));
}

double doe_rsbench_doppler_xs(const int64_t *input, size_t length) {
    if (input == NULL || length < 10 || length > MAX_LENGTH) return INVALID_RESULT;
    const int64_t nwin = input[0], npole = input[1], nl = input[2], energy_raw = input[3];
    if (nwin < 1 || nwin > MAX_WINDOWS || npole < 0 || npole > MAX_POLES || nl < 1 || nl > MAX_L ||
        energy_raw < 0 || energy_raw > 1000000) return INVALID_RESULT;
    const size_t factor_base = 4 + (size_t)nwin * 5;
    const size_t pole_base = factor_base + (size_t)nl;
    if (length != pole_base + (size_t)npole * 9) return INVALID_RESULT;
    const double energy = (double)energy_raw / SCALE;
    double bg_t[MAX_WINDOWS], bg_a[MAX_WINDOWS], bg_f[MAX_WINDOWS];
    int starts[MAX_WINDOWS], ends[MAX_WINDOWS];
    for (int i = 0; i < nwin; ++i) {
        const size_t at = 4 + (size_t)i * 5;
        if (input[at] < 0 || input[at] > 1000000 || input[at + 1] < 0 || input[at + 1] > 1000000 ||
            input[at + 2] < 0 || input[at + 2] > 1000000 || input[at + 3] < 0 || input[at + 3] > npole ||
            input[at + 4] < input[at + 3] || input[at + 4] > npole) return INVALID_RESULT;
        bg_t[i] = (double)input[at] / SCALE;
        bg_a[i] = (double)input[at + 1] / SCALE;
        bg_f[i] = (double)input[at + 2] / SCALE;
        starts[i] = (int)input[at + 3];
        ends[i] = (int)input[at + 4];
    }
    double pseudo[MAX_L];
    Cpx sig_t_factors[MAX_L];
    for (int i = 0; i < nl; ++i) {
        const int64_t raw = input[factor_base + (size_t)i];
        if (raw < 0 || raw > 1000000) return INVALID_RESULT;
        pseudo[i] = (double)raw / SCALE;
    }
    for (int i = 0; i < npole; ++i) {
        const size_t at = pole_base + (size_t)i * 9;
        for (int j = 0; j < 8; ++j) if (input[at + (size_t)j] < 0 || input[at + (size_t)j] > 152500000) return INVALID_RESULT;
        if (input[at + 8] < 0 || input[at + 8] >= nl) return INVALID_RESULT;
    }
    double spacing = 1.0 / (double)nwin;
    int window = (int)(energy / spacing);
    if (window == nwin) window--;
    if (window < 0 || window >= nwin) return INVALID_RESULT;

    const double root_energy = sqrt(energy);
    for (int i = 0; i < nl; ++i) {
        double phi = pseudo[i] * root_energy;
        if (i == 1) phi -= -atan(phi);
        else if (i == 2) phi -= atan(3.0 * phi / (3.0 - phi * phi));
        else if (i == 3) phi -= atan(phi * (15.0 - phi * phi) / (15.0 - 6.0 * phi * phi));
        phi *= 2.0;
        sig_t_factors[i] = (Cpx){cos(phi), -sin(phi)};
    }

    double sig_t = energy * bg_t[window];
    double sig_a = energy * bg_a[window];
    double sig_f = energy * bg_f[window];
    for (int i = starts[window]; i < ends[window]; ++i) {
        const size_t at = pole_base + (size_t)i * 9;
        const Cpx ea = {(double)input[at] / SCALE, (double)input[at + 1] / SCALE};
        const Cpx rt = {(double)input[at + 2] / SCALE, (double)input[at + 3] / SCALE};
        const Cpx ra = {(double)input[at + 4] / SCALE, (double)input[at + 5] / SCALE};
        const Cpx rf = {(double)input[at + 6] / SCALE, (double)input[at + 7] / SCALE};
        const int l_value = (int)input[at + 8];
        const Cpx z = scale(sub((Cpx){energy, 0.0}, ea), 0.5);
        if (z.re == 0.0 && z.im == 0.0) return INVALID_RESULT;
        const Cpx faddeeva = fast_nuclear_w(z);
        sig_t += mul(mul(rt, faddeeva), sig_t_factors[l_value]).re;
        sig_a += mul(ra, faddeeva).re;
        sig_f += mul(rf, faddeeva).re;
    }
    const double sig_e = sig_t - sig_a;
    const double result = sig_t + 2.0 * sig_a + 3.0 * sig_f + 5.0 * sig_e;
    return isfinite(result) ? result : INVALID_RESULT;
}
