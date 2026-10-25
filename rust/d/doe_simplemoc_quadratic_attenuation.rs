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
 */

const INVALID_RESULT: f64 = -1.0e300;
const RAW_LIMIT: i64 = 10_000_000;

#[inline]
fn decode(raw: i64) -> f32 {
    raw as f32 / 1_000_000.0_f32
}

#[inline]
fn one_minus_exp(tau: f32) -> f32 {
    let dx: f32 = 10.0_f32 / 353.0_f32;
    let max_value: f32 = 10.0_f32 - dx;
    if tau > max_value {
        return 1.0;
    }
    let rounded_interval = tau / dx + 0.5_f32 * dx;
    let interval = rounded_interval as i32;
    let anchor: f32 = interval as f32 * dx;
    let exponential: f32 = (-anchor).exp();
    let slope: f32 = -exponential;
    let anchor_minus_one: f32 = anchor - 1.0_f32;
    let product: f32 = anchor_minus_one * exponential;
    let intercept: f32 = 1.0_f32 + product;
    slope * tau + intercept
}

#[no_mangle]
pub unsafe extern "C" fn doe_simplemoc_quadratic_attenuation(
    values: *const i64,
    length: usize,
) -> f64 {
    if values.is_null() || !(13..=31).contains(&length) {
        return INVALID_RESULT;
    }
    let groups_raw = *values;
    if !(1..=4).contains(&groups_raw) || length != 7 + 6 * groups_raw as usize {
        return INVALID_RESULT;
    }
    let input = std::slice::from_raw_parts(values, length);
    for &raw in &input[1..] {
        if !(-RAW_LIMIT..=RAW_LIMIT).contains(&raw) {
            return INVALID_RESULT;
        }
    }

    let zin_raw = input[1];
    let dz_raw = input[2];
    let ds_raw = input[3];
    let mu_raw = input[4];
    let az_weight_raw = input[5];
    let polar_weight_raw = input[6];
    if !(0..=1_000_000).contains(&mu_raw)
        || !(0..=1_000_000).contains(&az_weight_raw)
        || !(0..=1_000_000).contains(&polar_weight_raw)
    {
        return INVALID_RESULT;
    }

    let zin = decode(zin_raw);
    let dz = decode(dz_raw);
    let ds = decode(ds_raw);
    let mu = decode(mu_raw);
    let az_weight = decode(az_weight_raw);
    let polar_weight = decode(polar_weight_raw);
    if !(0.01_f32..=10.0_f32).contains(&dz)
        || !(0.001_f32..=10.0_f32).contains(&ds)
        || (2.0_f32 * zin).abs() > dz
    {
        return INVALID_RESULT;
    }
    let mut checksum: f32 = 0.0;

    for group in 0..groups_raw as usize {
        let offset = 7 + 6 * group;
        let y1_raw = input[offset];
        let y2_raw = input[offset + 1];
        let y3_raw = input[offset + 2];
        let sigma_raw = input[offset + 3];
        let psi_raw = input[offset + 4];
        let tally_raw = input[offset + 5];
        if sigma_raw <= 0 || psi_raw < 0 || tally_raw < 0 {
            return INVALID_RESULT;
        }

        let y1 = decode(y1_raw);
        let y2 = decode(y2_raw);
        let y3 = decode(y3_raw);
        let sigma = decode(sigma_raw);
        let psi_in = decode(psi_raw);
        let tally_in = decode(tally_raw);
        if !(0.1_f32..=10.0_f32).contains(&sigma) {
            return INVALID_RESULT;
        }
        let tau: f32 = sigma * ds;
        if tau <= 0.0_f32 || tau > 10.0_f32 {
            return INVALID_RESULT;
        }

        let two_dz: f32 = 2.0_f32 * dz;
        let c1_numerator: f32 = y1 - y3;
        let c1: f32 = c1_numerator / two_dz;

        let twice_y2: f32 = 2.0_f32 * y2;
        let c2_partial: f32 = y1 - twice_y2;
        let c2_numerator: f32 = c2_partial + y3;
        let c2_denominator_partial: f32 = 2.0_f32 * dz;
        let c2_denominator: f32 = c2_denominator_partial * dz;
        let c2: f32 = c2_numerator / c2_denominator;

        let q0_linear: f32 = c1 * zin;
        let q0_partial: f32 = y2 + q0_linear;
        let q0_quadratic_partial: f32 = c2 * zin;
        let q0_quadratic: f32 = q0_quadratic_partial * zin;
        let q0: f32 = q0_partial + q0_quadratic;
        let q1_twice_c2: f32 = 2.0_f32 * c2;
        let q1_shift: f32 = q1_twice_c2 * zin;
        let q1: f32 = c1 + q1_shift;
        let q2: f32 = c2;

        let attenuation: f32 = one_minus_exp(tau);
        let sigma_squared: f32 = sigma * sigma;
        let tau_minus_two: f32 = tau - 2.0_f32;
        let reuse_first: f32 = tau * tau_minus_two;
        let reuse_numerator: f32 = 2.0_f32 * attenuation;
        let reuse_denominator: f32 = sigma * sigma_squared;
        let reuse_second: f32 = reuse_numerator / reuse_denominator;
        let reuse: f32 = reuse_first + reuse_second;

        let integral_first_product: f32 = q0 * tau;
        let sigma_psi: f32 = sigma * psi_in;
        let sigma_psi_minus_q0: f32 = sigma_psi - q0;
        let integral_first_tail: f32 = sigma_psi_minus_q0 * attenuation;
        let integral_first_numerator: f32 = integral_first_product + integral_first_tail;
        let integral_first: f32 = integral_first_numerator / sigma_squared;
        let integral_second_left: f32 = q1 * mu;
        let integral_second: f32 = integral_second_left * reuse;
        let tau_minus_three: f32 = tau - 3.0_f32;
        let tau_inner_product: f32 = tau * tau_minus_three;
        let tau_inner: f32 = tau_inner_product + 6.0_f32;
        let tau_cubic_term: f32 = tau * tau_inner;
        let six_attenuation: f32 = 6.0_f32 * attenuation;
        let integral_third_inner: f32 = tau_cubic_term - six_attenuation;
        let integral_third_left: f32 = q2 * mu;
        let integral_third_left_squared: f32 = integral_third_left * mu;
        let integral_third_numerator: f32 = integral_third_left_squared * integral_third_inner;
        let integral_denominator_partial: f32 = 3.0_f32 * sigma_squared;
        let integral_third_denominator: f32 = integral_denominator_partial * sigma_squared;
        let integral_third: f32 = integral_third_numerator / integral_third_denominator;
        let integral_partial: f32 = integral_first + integral_second;
        let integral: f32 = integral_partial + integral_third;

        let weight_product: f32 = polar_weight * az_weight;
        let tally_delta: f32 = weight_product * integral;
        let tally_out: f32 = tally_in + tally_delta;

        let psi_first_numerator: f32 = q0 * attenuation;
        let psi_first: f32 = psi_first_numerator / sigma;
        let tau_minus_attenuation: f32 = tau - attenuation;
        let psi_second_left: f32 = q1 * mu;
        let psi_second_product: f32 = psi_second_left * tau_minus_attenuation;
        let psi_second: f32 = psi_second_product / sigma_squared;
        let psi_third_left: f32 = q2 * mu;
        let psi_third_squared: f32 = psi_third_left * mu;
        let psi_third: f32 = psi_third_squared * reuse;
        let one_minus_attenuation: f32 = 1.0_f32 - attenuation;
        let psi_fourth: f32 = psi_in * one_minus_attenuation;
        let psi_partial: f32 = psi_first + psi_second;
        let psi_partial: f32 = psi_partial + psi_third;
        let psi_out: f32 = psi_partial + psi_fourth;

        let output_sum: f32 = tally_out + psi_out;
        let weighted_output: f32 = (group as f32 + 1.0_f32) * output_sum;
        checksum = checksum + weighted_output;
    }
    checksum as f64
}
