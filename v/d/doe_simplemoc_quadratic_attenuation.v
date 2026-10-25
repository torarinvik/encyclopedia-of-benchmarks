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

module doe_simplemoc_quadratic_attenuation

import math

const raw_limit = i64(10_000_000)
const invalid_result = -1.0e300

fn decode(raw i64) f32 {
	return f32(raw) / f32(1_000_000.0)
}

fn one_minus_exp(tau f32) f32 {
	dx := f32(10.0) / f32(353.0)
	max_value := f32(10.0) - dx
	if tau > max_value { return f32(1.0) }
	rounded_interval := tau / dx + f32(0.5) * dx
	interval := int(rounded_interval)
	anchor := f32(interval) * dx
	exponential := f32(math.exp(-f64(anchor)))
	slope := -exponential
	anchor_minus_one := anchor - f32(1.0)
	product := anchor_minus_one * exponential
	intercept := f32(1.0) + product
	return slope * tau + intercept
}

@[export: 'doe_simplemoc_quadratic_attenuation']
pub fn doe_simplemoc_quadratic_attenuation(values &i64, length usize) f64 {
	unsafe {
		if values == nil || length < 13 || length > 31 { return invalid_result }
		groups_raw := values[0]
		if groups_raw < 1 || groups_raw > 4 || length != usize(7 + 6 * groups_raw) {
			return invalid_result
		}
		for index in 1 .. int(length) {
			raw := values[index]
			if raw < -raw_limit || raw > raw_limit { return invalid_result }
		}

		zin := decode(values[1])
		dz := decode(values[2])
		ds := decode(values[3])
		mu_raw := values[4]
		az_weight_raw := values[5]
		polar_weight_raw := values[6]
		if dz < f32(0.01) || dz > f32(10.0) || ds < f32(0.001) || ds > f32(10.0) ||
			mu_raw < 0 || mu_raw > 1_000_000 || az_weight_raw < 0 || az_weight_raw > 1_000_000 ||
			polar_weight_raw < 0 || polar_weight_raw > 1_000_000 {
			return invalid_result
		}
		two_zin := f32(2.0) * zin
		abs_two_zin := if two_zin < f32(0.0) { -two_zin } else { two_zin }
		if abs_two_zin > dz { return invalid_result }
		mu := decode(mu_raw)
		az_weight := decode(az_weight_raw)
		polar_weight := decode(polar_weight_raw)
		mut checksum := f32(0.0)

		for group in 0 .. int(groups_raw) {
			offset := 7 + 6 * group
			y1 := decode(values[offset])
			y2 := decode(values[offset + 1])
			y3 := decode(values[offset + 2])
			sigma_raw := values[offset + 3]
			psi_raw := values[offset + 4]
			tally_raw := values[offset + 5]
			if sigma_raw < 100_000 || sigma_raw > 10_000_000 || psi_raw < 0 || tally_raw < 0 {
				return invalid_result
			}
			sigma := decode(sigma_raw)
			psi_in := decode(psi_raw)
			tally_in := decode(tally_raw)
			tau := sigma * ds
			if tau <= f32(0.0) || tau > f32(10.0) { return invalid_result }

			two_dz := f32(2.0) * dz
			c1_numerator := y1 - y3
			c1 := c1_numerator / two_dz
			twice_y2 := f32(2.0) * y2
			c2_partial := y1 - twice_y2
			c2_numerator := c2_partial + y3
			c2_denominator_partial := f32(2.0) * dz
			c2_denominator := c2_denominator_partial * dz
			c2 := c2_numerator / c2_denominator

			q0_linear := c1 * zin
			q0_partial := y2 + q0_linear
			q0_quadratic_partial := c2 * zin
			q0_quadratic := q0_quadratic_partial * zin
			q0 := q0_partial + q0_quadratic
			q1_twice_c2 := f32(2.0) * c2
			q1_shift := q1_twice_c2 * zin
			q1 := c1 + q1_shift
			q2 := c2

			attenuation := one_minus_exp(tau)
			sigma_squared := sigma * sigma
			tau_minus_two := tau - f32(2.0)
			reuse_first := tau * tau_minus_two
			reuse_numerator := f32(2.0) * attenuation
			reuse_denominator := sigma * sigma_squared
			reuse_second := reuse_numerator / reuse_denominator
			reuse := reuse_first + reuse_second

			integral_first_product := q0 * tau
			sigma_psi := sigma * psi_in
			sigma_psi_minus_q0 := sigma_psi - q0
			integral_first_tail := sigma_psi_minus_q0 * attenuation
			integral_first_numerator := integral_first_product + integral_first_tail
			integral_first := integral_first_numerator / sigma_squared
			integral_second_left := q1 * mu
			integral_second := integral_second_left * reuse
			tau_minus_three := tau - f32(3.0)
			tau_inner_product := tau * tau_minus_three
			tau_inner := tau_inner_product + f32(6.0)
			tau_cubic_term := tau * tau_inner
			six_attenuation := f32(6.0) * attenuation
			integral_third_inner := tau_cubic_term - six_attenuation
			integral_third_left := q2 * mu
			integral_third_left_squared := integral_third_left * mu
			integral_third_numerator := integral_third_left_squared * integral_third_inner
			integral_denominator_partial := f32(3.0) * sigma_squared
			integral_third_denominator := integral_denominator_partial * sigma_squared
			integral_third := integral_third_numerator / integral_third_denominator
			integral_partial := integral_first + integral_second
			integral := integral_partial + integral_third

			weight_product := polar_weight * az_weight
			tally_delta := weight_product * integral
			tally_out := tally_in + tally_delta

			psi_first_numerator := q0 * attenuation
			psi_first := psi_first_numerator / sigma
			tau_minus_attenuation := tau - attenuation
			psi_second_left := q1 * mu
			psi_second_product := psi_second_left * tau_minus_attenuation
			psi_second := psi_second_product / sigma_squared
			psi_third_left := q2 * mu
			psi_third_squared := psi_third_left * mu
			psi_third := psi_third_squared * reuse
			one_minus_attenuation := f32(1.0) - attenuation
			psi_fourth := psi_in * one_minus_attenuation
			psi_partial_1 := psi_first + psi_second
			psi_partial_2 := psi_partial_1 + psi_third
			psi_out := psi_partial_2 + psi_fourth

			output_sum := tally_out + psi_out
			weighted_output := f32(group + 1) * output_sum
			checksum = checksum + weighted_output
		}
		return f64(checksum)
	}
}
