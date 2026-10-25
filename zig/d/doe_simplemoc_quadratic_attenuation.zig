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

const raw_limit: i64 = 10_000_000;
const invalid_result: f64 = -1.0e300;

fn decode(raw: i64) f32 {
	return @as(f32, @floatFromInt(raw)) / 1_000_000.0;
}

fn oneMinusExp(tau: f32) f32 {
	const dx: f32 = 10.0 / 353.0;
	const max_value: f32 = 10.0 - dx;
	if (tau > max_value) return 1.0;
	const rounded_interval: f32 = tau / dx + 0.5 * dx;
	const interval: i32 = @intFromFloat(rounded_interval);
	const anchor: f32 = @as(f32, @floatFromInt(interval)) * dx;
	const exponential: f32 = @exp(-anchor);
	const slope: f32 = -exponential;
	const anchor_minus_one: f32 = anchor - 1.0;
	const product: f32 = anchor_minus_one * exponential;
	const intercept: f32 = 1.0 + product;
	return slope * tau + intercept;
}

pub export fn doe_simplemoc_quadratic_attenuation(values: [*c]const i64, length: usize) f64 {
	if (values == null or length < 13 or length > 31) return invalid_result;
	const groups_raw = values[0];
	if (groups_raw < 1 or groups_raw > 4) return invalid_result;
	const groups: usize = @intCast(groups_raw);
	if (length != 7 + 6 * groups) return invalid_result;
	for (1..length) |index| {
		const raw = values[index];
		if (raw < -raw_limit or raw > raw_limit) return invalid_result;
	}

	const zin = decode(values[1]);
	const dz = decode(values[2]);
	const ds = decode(values[3]);
	const mu_raw = values[4];
	const az_weight_raw = values[5];
	const polar_weight_raw = values[6];
	if (dz < 0.01 or dz > 10.0 or ds < 0.001 or ds > 10.0 or
		mu_raw < 0 or mu_raw > 1_000_000 or az_weight_raw < 0 or az_weight_raw > 1_000_000 or
		polar_weight_raw < 0 or polar_weight_raw > 1_000_000) return invalid_result;
	const two_zin: f32 = 2.0 * zin;
	const abs_two_zin = @abs(two_zin);
	if (abs_two_zin > dz) return invalid_result;
	const mu = decode(mu_raw);
	const az_weight = decode(az_weight_raw);
	const polar_weight = decode(polar_weight_raw);
	var checksum: f32 = 0.0;

	for (0..groups) |group| {
		const offset = 7 + 6 * group;
		const y1 = decode(values[offset]);
		const y2 = decode(values[offset + 1]);
		const y3 = decode(values[offset + 2]);
		const sigma_raw = values[offset + 3];
		const psi_raw = values[offset + 4];
		const tally_raw = values[offset + 5];
		if (sigma_raw < 100_000 or sigma_raw > 10_000_000 or psi_raw < 0 or tally_raw < 0) {
			return invalid_result;
		}
		const sigma = decode(sigma_raw);
		const psi_in = decode(psi_raw);
		const tally_in = decode(tally_raw);
		const tau: f32 = sigma * ds;
		if (tau <= 0.0 or tau > 10.0) return invalid_result;

		const two_dz: f32 = 2.0 * dz;
		const c1_numerator: f32 = y1 - y3;
		const c1: f32 = c1_numerator / two_dz;
		const twice_y2: f32 = 2.0 * y2;
		const c2_partial: f32 = y1 - twice_y2;
		const c2_numerator: f32 = c2_partial + y3;
		const c2_denominator_partial: f32 = 2.0 * dz;
		const c2_denominator: f32 = c2_denominator_partial * dz;
		const c2: f32 = c2_numerator / c2_denominator;

		const q0_linear: f32 = c1 * zin;
		const q0_partial: f32 = y2 + q0_linear;
		const q0_quadratic_partial: f32 = c2 * zin;
		const q0_quadratic: f32 = q0_quadratic_partial * zin;
		const q0: f32 = q0_partial + q0_quadratic;
		const q1_twice_c2: f32 = 2.0 * c2;
		const q1_shift: f32 = q1_twice_c2 * zin;
		const q1: f32 = c1 + q1_shift;
		const q2 = c2;

		const attenuation = oneMinusExp(tau);
		const sigma_squared: f32 = sigma * sigma;
		const tau_minus_two: f32 = tau - 2.0;
		const reuse_first: f32 = tau * tau_minus_two;
		const reuse_numerator: f32 = 2.0 * attenuation;
		const reuse_denominator: f32 = sigma * sigma_squared;
		const reuse_second: f32 = reuse_numerator / reuse_denominator;
		const reuse: f32 = reuse_first + reuse_second;

		const integral_first_product: f32 = q0 * tau;
		const sigma_psi: f32 = sigma * psi_in;
		const sigma_psi_minus_q0: f32 = sigma_psi - q0;
		const integral_first_tail: f32 = sigma_psi_minus_q0 * attenuation;
		const integral_first_numerator: f32 = integral_first_product + integral_first_tail;
		const integral_first: f32 = integral_first_numerator / sigma_squared;
		const integral_second_left: f32 = q1 * mu;
		const integral_second: f32 = integral_second_left * reuse;
		const tau_minus_three: f32 = tau - 3.0;
		const tau_inner_product: f32 = tau * tau_minus_three;
		const tau_inner: f32 = tau_inner_product + 6.0;
		const tau_cubic_term: f32 = tau * tau_inner;
		const six_attenuation: f32 = 6.0 * attenuation;
		const integral_third_inner: f32 = tau_cubic_term - six_attenuation;
		const integral_third_left: f32 = q2 * mu;
		const integral_third_left_squared: f32 = integral_third_left * mu;
		const integral_third_numerator: f32 = integral_third_left_squared * integral_third_inner;
		const integral_denominator_partial: f32 = 3.0 * sigma_squared;
		const integral_third_denominator: f32 = integral_denominator_partial * sigma_squared;
		const integral_third: f32 = integral_third_numerator / integral_third_denominator;
		const integral_partial: f32 = integral_first + integral_second;
		const integral: f32 = integral_partial + integral_third;

		const weight_product: f32 = polar_weight * az_weight;
		const tally_delta: f32 = weight_product * integral;
		const tally_out: f32 = tally_in + tally_delta;

		const psi_first_numerator: f32 = q0 * attenuation;
		const psi_first: f32 = psi_first_numerator / sigma;
		const tau_minus_attenuation: f32 = tau - attenuation;
		const psi_second_left: f32 = q1 * mu;
		const psi_second_product: f32 = psi_second_left * tau_minus_attenuation;
		const psi_second: f32 = psi_second_product / sigma_squared;
		const psi_third_left: f32 = q2 * mu;
		const psi_third_squared: f32 = psi_third_left * mu;
		const psi_third: f32 = psi_third_squared * reuse;
		const one_minus_attenuation: f32 = 1.0 - attenuation;
		const psi_fourth: f32 = psi_in * one_minus_attenuation;
		const psi_partial_1: f32 = psi_first + psi_second;
		const psi_partial_2: f32 = psi_partial_1 + psi_third;
		const psi_out: f32 = psi_partial_2 + psi_fourth;

		const output_sum: f32 = tally_out + psi_out;
		const group_multiplier: f32 = @as(f32, @floatFromInt(group + 1));
		const weighted_output: f32 = group_multiplier * output_sum;
		checksum = checksum + weighted_output;
	}
	return @as(f64, checksum);
}
