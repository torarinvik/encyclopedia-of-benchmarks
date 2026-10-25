/*
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
 * Bounded source-shaped profile of SimpleMOC solver.c::attenuate_fluxes.
 */
package doe_simplemoc_quadratic_attenuation

import "core:c"
import "core:math"

INVALID_RESULT :: f64(-1.0e300)
FIXED_SCALE :: f32(1_000_000.0)
MAX_RAW :: i64(10_000_000)
MAX_GROUPS :: i64(4)
TABLE_SIZE :: f32(353.0)

add32 :: proc(a, b: f32) -> f32 { return f32(a + b) }
sub32 :: proc(a, b: f32) -> f32 { return f32(a - b) }
mul32 :: proc(a, b: f32) -> f32 { return f32(a * b) }
div32 :: proc(a, b: f32) -> f32 { return f32(a / b) }
fixed :: proc(raw: i64) -> f32 { return div32(f32(raw), FIXED_SCALE) }

exp_table :: proc(tau: f32) -> f32 {
	dx := div32(f32(10.0), TABLE_SIZE)
	max_value := sub32(f32(10.0), dx)
	if tau > max_value do return f32(1.0)
	rounded_index := add32(div32(tau, dx), mul32(f32(0.5), dx))
	interval := int(rounded_index)
	anchor := mul32(f32(interval), dx)
	e := f32(math.exp_f64(-f64(anchor)))
	slope := -e
	anchor_offset := sub32(anchor, f32(1.0))
	intercept_product := mul32(anchor_offset, e)
	intercept := add32(f32(1.0), intercept_product)
	return add32(mul32(slope, tau), intercept)
}

@(export)
doe_simplemoc_quadratic_attenuation :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 13 || length > 31 do return INVALID_RESULT
	groups_raw := input[0]
	if groups_raw < 1 || groups_raw > MAX_GROUPS do return INVALID_RESULT
	groups := int(groups_raw)
	if length != c.size_t(7 + 6 * groups) do return INVALID_RESULT

	for index := 1; index < int(length); index += 1 {
		if input[index] < -MAX_RAW || input[index] > MAX_RAW do return INVALID_RESULT
	}

	zin_raw, dz_raw, ds_raw := input[1], input[2], input[3]
	mu_raw, az_weight_raw, polar_weight_raw := input[4], input[5], input[6]
	if dz_raw < 10_000 || ds_raw < 1_000 ||
		mu_raw < 0 || mu_raw > 1_000_000 ||
		az_weight_raw < 0 || az_weight_raw > 1_000_000 ||
		polar_weight_raw < 0 || polar_weight_raw > 1_000_000 do return INVALID_RESULT

	zin, dz, ds := fixed(zin_raw), fixed(dz_raw), fixed(ds_raw)
	mu, az_weight, polar_weight := fixed(mu_raw), fixed(az_weight_raw), fixed(polar_weight_raw)
	twice_zin := mul32(f32(2.0), zin)
	if twice_zin < 0 do twice_zin = -twice_zin
	if twice_zin > dz do return INVALID_RESULT
	weight := mul32(polar_weight, az_weight)
	checksum := f32(0.0)

	for group := 0; group < groups; group += 1 {
		base := 7 + 6 * group
		previous_raw, center_raw, next_raw := input[base], input[base+1], input[base+2]
		sigma_raw, psi_raw, tally_raw := input[base+3], input[base+4], input[base+5]
		if sigma_raw < 100_000 || psi_raw < 0 || tally_raw < 0 do return INVALID_RESULT

		previous, center, next := fixed(previous_raw), fixed(center_raw), fixed(next_raw)
		sigma, psi, tally := fixed(sigma_raw), fixed(psi_raw), fixed(tally_raw)

		twice_dz := mul32(f32(2.0), dz)
		c1 := div32(sub32(previous, next), twice_dz)
		twice_center := mul32(f32(2.0), center)
		c2_numerator := add32(sub32(previous, twice_center), next)
		c2_denominator := mul32(twice_dz, dz)
		c2 := div32(c2_numerator, c2_denominator)

		q0_linear := mul32(c1, zin)
		q0_quadratic_first := mul32(c2, zin)
		q0_quadratic := mul32(q0_quadratic_first, zin)
		q0 := add32(add32(center, q0_linear), q0_quadratic)
		q1_curve := mul32(f32(2.0), c2)
		q1 := add32(c1, mul32(q1_curve, zin))
		q2 := c2

		tau := mul32(sigma, ds)
		if tau <= 0 || tau > f32(10.0) do return INVALID_RESULT
		exp_value := exp_table(tau)
		sigma_squared := mul32(sigma, sigma)
		reuse_numerator := mul32(f32(2.0), exp_value)
		reuse_denominator := mul32(sigma, sigma_squared)
		reuse_quotient := div32(reuse_numerator, reuse_denominator)
		reuse_polynomial := mul32(tau, sub32(tau, f32(2.0)))
		reuse := add32(reuse_polynomial, reuse_quotient)

		q0_tau := mul32(q0, tau)
		sigma_psi := mul32(sigma, psi)
		difference := sub32(sigma_psi, q0)
		difference_exp := mul32(difference, exp_value)
		integral_first := div32(add32(q0_tau, difference_exp), sigma_squared)
		integral_second := mul32(mul32(q1, mu), reuse)

		mu_squared := mul32(mu, mu)
		tau_minus_three := sub32(tau, f32(3.0))
		tau_inner := add32(mul32(tau, tau_minus_three), f32(6.0))
		tau_outer := mul32(tau, tau_inner)
		six_exp := mul32(f32(6.0), exp_value)
		integral_polynomial := sub32(tau_outer, six_exp)
		integral_denominator := mul32(mul32(f32(3.0), sigma_squared), sigma_squared)
		integral_third := div32(mul32(mul32(q2, mu_squared), integral_polynomial), integral_denominator)
		flux_integral := add32(add32(integral_first, integral_second), integral_third)
		tally_delta := mul32(weight, flux_integral)
		tally_out := add32(tally, tally_delta)

		term1 := div32(mul32(q0, exp_value), sigma)
		term2_numerator := mul32(mul32(q1, mu), sub32(tau, exp_value))
		term2 := div32(term2_numerator, sigma_squared)
		term3 := mul32(mul32(q2, mu_squared), reuse)
		term4 := mul32(psi, sub32(f32(1.0), exp_value))
		psi_out := add32(add32(add32(term1, term2), term3), term4)

		group_total := add32(tally_out, psi_out)
		weighted_total := mul32(f32(group + 1), group_total)
		checksum = add32(checksum, weighted_total)
	}
	return f64(checksum)
}
