/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 John Tramm
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Bounded adaptation of SimpleMOC's quadratic-source attenuate_fluxes kernel.
 */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_GROUPS 4
#define MAX_RAW 10000000LL

/* Force each source-level operation to round to binary32 before the next one. */
static float add32(float left, float right) { volatile float result = left + right; return result; }
static float sub32(float left, float right) { volatile float result = left - right; return result; }
static float mul32(float left, float right) { volatile float result = left * right; return result; }
static float div32(float left, float right) { volatile float result = left / right; return result; }

static float decode32(int64_t raw) {
    return div32((float)raw, 1000000.0f);
}

static float exp32(float anchor) {
    volatile float result = (float)exp(-(double)anchor);
    return result;
}

static float interpolate_one_minus_exp(float tau) {
    const float dx = (float)(10.0 / 353.0);
    const float max_value = sub32(10.0f, dx);
    if (tau > max_value) return 1.0f;

    const float ratio = div32(tau, dx);
    const float offset = mul32(0.5f, dx);
    const int interval = (int)add32(ratio, offset);
    if (interval < 0 || interval >= 353) return NAN;

    const float anchor = mul32((float)interval, dx);
    const float exponential = exp32(anchor);
    const float slope = -exponential;
    const float intercept = add32(1.0f, mul32(sub32(anchor, 1.0f), exponential));
    return add32(mul32(slope, tau), intercept);
}

double doe_simplemoc_quadratic_attenuation(const int64_t *input, size_t length) {
    if (input == NULL || length < 13 || length > 31) return INVALID_RESULT;
    const int64_t groups_raw = input[0];
    if (groups_raw < 1 || groups_raw > MAX_GROUPS) return INVALID_RESULT;
    const size_t groups = (size_t)groups_raw;
    if (length != 7 + 6 * groups) return INVALID_RESULT;

    for (size_t i = 1; i < length; ++i)
        if (input[i] < -MAX_RAW || input[i] > MAX_RAW) return INVALID_RESULT;
    const int64_t zin_raw = input[1], dz_raw = input[2], ds_raw = input[3];
    const int64_t mu_raw = input[4], az_raw = input[5], polar_raw = input[6];
    if (dz_raw < 10000 || dz_raw > 10000000 || ds_raw < 1000 || ds_raw > 10000000 ||
        mu_raw < 0 || mu_raw > 1000000 ||
        az_raw < 0 || az_raw > 1000000 || polar_raw < 0 || polar_raw > 1000000)
        return INVALID_RESULT;

    const float zin = decode32(zin_raw);
    const float dz = decode32(dz_raw);
    const float ds = decode32(ds_raw);
    const float mu = decode32(mu_raw);
    const float az_weight = decode32(az_raw);
    const float polar_weight = decode32(polar_raw);
    const float twice_zin = mul32(2.0f, zin);
    if (twice_zin > dz || -twice_zin > dz) return INVALID_RESULT;
    const float weight = mul32(polar_weight, az_weight);
    const float mu2 = mul32(mu, mu);
    float checksum = 0.0f;

    for (size_t g = 0; g < groups; ++g) {
        const size_t at = 7 + 6 * g;
        const int64_t y1_raw = input[at], y2_raw = input[at + 1], y3_raw = input[at + 2];
        const int64_t sigma_raw = input[at + 3], psi_raw = input[at + 4], tally_raw = input[at + 5];
        if (sigma_raw < 100000 || sigma_raw > 10000000 || psi_raw < 0 || tally_raw < 0)
            return INVALID_RESULT;

        const float y1 = decode32(y1_raw), y2 = decode32(y2_raw), y3 = decode32(y3_raw);
        const float sigma = decode32(sigma_raw), psi = decode32(psi_raw), tally_in = decode32(tally_raw);
        const float tau = mul32(sigma, ds);
        if (!(tau > 0.0f) || tau > 10.0f) return INVALID_RESULT;

        const float c1_numerator = sub32(y1, y3);
        const float c1_denominator = mul32(2.0f, dz);
        const float c1 = div32(c1_numerator, c1_denominator);
        const float c2_numerator = add32(sub32(y1, mul32(2.0f, y2)), y3);
        const float c2_denominator = mul32(mul32(2.0f, dz), dz);
        const float c2 = div32(c2_numerator, c2_denominator);

        const float c1_z = mul32(c1, zin);
        const float c2_z2 = mul32(mul32(c2, zin), zin);
        const float q0 = add32(add32(y2, c1_z), c2_z2);
        const float q1 = add32(c1, mul32(mul32(2.0f, c2), zin));
        const float q2 = c2;

        const float exp_value = interpolate_one_minus_exp(tau);
        if (!isfinite(exp_value)) return INVALID_RESULT;
        const float sigma2 = mul32(sigma, sigma);
        const float tau_minus_two = sub32(tau, 2.0f);
        const float reuse_left = mul32(tau, tau_minus_two);
        const float reuse_num = mul32(2.0f, exp_value);
        const float reuse_den = mul32(sigma, sigma2);
        const float reuse = add32(reuse_left, div32(reuse_num, reuse_den));

        const float integral_first_a = mul32(q0, tau);
        const float integral_first_b = mul32(sigma, psi);
        const float integral_first_c = sub32(integral_first_b, q0);
        const float integral_first_d = mul32(integral_first_c, exp_value);
        const float integral_first = div32(add32(integral_first_a, integral_first_d), sigma2);
        const float integral_second = mul32(mul32(q1, mu), reuse);

        const float inner_a = sub32(tau, 3.0f);
        const float inner_b = add32(mul32(tau, inner_a), 6.0f);
        const float inner_c = mul32(tau, inner_b);
        const float inner_d = sub32(inner_c, mul32(6.0f, exp_value));
        const float integral_third_num = mul32(mul32(q2, mu2), inner_d);
        const float integral_third_den = mul32(mul32(3.0f, sigma2), sigma2);
        const float integral_third = div32(integral_third_num, integral_third_den);
        const float flux_integral = add32(add32(integral_first, integral_second), integral_third);

        const float tally_out = add32(tally_in, mul32(weight, flux_integral));
        const float psi_term1 = div32(mul32(q0, exp_value), sigma);
        const float psi_term2 = div32(mul32(mul32(q1, mu), sub32(tau, exp_value)), sigma2);
        const float psi_term3 = mul32(mul32(q2, mu2), reuse);
        const float psi_term4 = mul32(psi, sub32(1.0f, exp_value));
        const float psi_out = add32(add32(add32(psi_term1, psi_term2), psi_term3), psi_term4);

        const float group_value = add32(tally_out, psi_out);
        checksum = add32(checksum, mul32((float)(g + 1), group_value));
    }

    return isfinite(checksum) ? (double)checksum : INVALID_RESULT;
}
