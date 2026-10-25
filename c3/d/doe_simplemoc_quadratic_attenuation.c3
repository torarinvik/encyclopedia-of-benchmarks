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
module doe_simplemoc_quadratic_attenuation;

const double INVALID_RESULT = -1e300;
import "math";

const long MAX_RAW = 10000000;
const long MAX_GROUPS = 4;

/* Non-inlined f32 operations keep each source-level step rounded to binary32. */
fn float add32(float left, float right) @noinline { return left + right; }
fn float sub32(float left, float right) @noinline { return left - right; }
fn float mul32(float left, float right) @noinline { return left * right; }
fn float div32(float left, float right) @noinline { return left / right; }
fn float decode32(long raw) @noinline { return div32((float)raw, 1000000.0f); }
fn float exp32(float anchor) @noinline { return (float)math.exp(-(double)anchor); }

fn float interpolate_one_minus_exp(float tau) {
    float dx = (float)(10.0 / 353.0);
    float max_value = sub32(10.0f, dx);
    if (tau > max_value) return 1.0f;
    float ratio = div32(tau, dx);
    float offset = mul32(0.5f, dx);
    long interval = (long)add32(ratio, offset);
    if (interval < 0 || interval >= 353) return -1.0f;
    float anchor = mul32((float)interval, dx);
    float exponential = exp32(anchor);
    float slope = -exponential;
    float intercept = add32(1.0f, mul32(sub32(anchor, 1.0f), exponential));
    return add32(mul32(slope, tau), intercept);
}

fn double doe_simplemoc_quadratic_attenuation(long* input, usz length)
    @export("doe_simplemoc_quadratic_attenuation") {
    if (input == null || length < 13 || length > 31) return INVALID_RESULT;
    long groups_raw = input[0];
    if (groups_raw < 1 || groups_raw > MAX_GROUPS) return INVALID_RESULT;
    usz groups = (usz)groups_raw;
    if (length != 7 + 6 * groups) return INVALID_RESULT;

    for (usz i = 1; i < length; i++)
        if (input[i] < -MAX_RAW || input[i] > MAX_RAW) return INVALID_RESULT;
    long zin_raw = input[1], dz_raw = input[2], ds_raw = input[3];
    long mu_raw = input[4], az_raw = input[5], polar_raw = input[6];
    if (dz_raw < 10000 || dz_raw > 10000000 || ds_raw < 1000 || ds_raw > 10000000 ||
        mu_raw < 0 || mu_raw > 1000000 || az_raw < 0 || az_raw > 1000000 ||
        polar_raw < 0 || polar_raw > 1000000) return INVALID_RESULT;

    float zin = decode32(zin_raw), dz = decode32(dz_raw), ds = decode32(ds_raw);
    float mu = decode32(mu_raw), az_weight = decode32(az_raw), polar_weight = decode32(polar_raw);
    float twice_zin = mul32(2.0f, zin);
    if (twice_zin > dz || -twice_zin > dz) return INVALID_RESULT;
    float weight = mul32(polar_weight, az_weight), mu2 = mul32(mu, mu);
    float checksum = 0.0f;
    for (usz g = 0; g < groups; g++) {
        usz at = 7 + 6 * g;
        long y1_raw = input[at], y2_raw = input[at + 1], y3_raw = input[at + 2];
        long sigma_raw = input[at + 3], psi_raw = input[at + 4], tally_raw = input[at + 5];
        if (sigma_raw < 100000 || sigma_raw > 10000000 || psi_raw < 0 || tally_raw < 0)
            return INVALID_RESULT;

        float y1 = decode32(y1_raw), y2 = decode32(y2_raw), y3 = decode32(y3_raw);
        float sigma = decode32(sigma_raw), psi = decode32(psi_raw), tally_in = decode32(tally_raw);
        float tau = mul32(sigma, ds);
        if (!(tau > 0.0f) || tau > 10.0f) return INVALID_RESULT;

        float c1 = div32(sub32(y1, y3), mul32(2.0f, dz));
        float c2_numerator = add32(sub32(y1, mul32(2.0f, y2)), y3);
        float c2_denominator = mul32(mul32(2.0f, dz), dz);
        float c2 = div32(c2_numerator, c2_denominator);
        float q0 = add32(add32(y2, mul32(c1, zin)), mul32(mul32(c2, zin), zin));
        float q1 = add32(c1, mul32(mul32(2.0f, c2), zin));
        float q2 = c2;

        float exp_value = interpolate_one_minus_exp(tau);
        if (exp_value < 0.0f) return INVALID_RESULT;
        float sigma2 = mul32(sigma, sigma);
        float reuse = add32(mul32(tau, sub32(tau, 2.0f)),
                            div32(mul32(2.0f, exp_value), mul32(sigma, sigma2)));

        float integral_first = div32(
            add32(mul32(q0, tau), mul32(sub32(mul32(sigma, psi), q0), exp_value)), sigma2);
        float integral_second = mul32(mul32(q1, mu), reuse);
        float inner = sub32(mul32(tau, add32(mul32(tau, sub32(tau, 3.0f)), 6.0f)),
                            mul32(6.0f, exp_value));
        float integral_third = div32(mul32(mul32(q2, mu2), inner),
                                     mul32(mul32(3.0f, sigma2), sigma2));
        float flux_integral = add32(add32(integral_first, integral_second), integral_third);

        float tally_out = add32(tally_in, mul32(weight, flux_integral));
        float psi_term1 = div32(mul32(q0, exp_value), sigma);
        float psi_term2 = div32(mul32(mul32(q1, mu), sub32(tau, exp_value)), sigma2);
        float psi_term3 = mul32(mul32(q2, mu2), reuse);
        float psi_term4 = mul32(psi, sub32(1.0f, exp_value));
        float psi_out = add32(add32(add32(psi_term1, psi_term2), psi_term3), psi_term4);
        checksum = add32(checksum, mul32((float)(g + 1), add32(tally_out, psi_out)));
    }
    return math.is_finite((double)checksum) ? (double)checksum : INVALID_RESULT;
}
