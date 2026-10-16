package butterworth_filter

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300

coefficients :: proc "contextless" (kind: i64, frequency, samplerate, gain_db, q_factor: f64) -> [6]f64 {
	w0 := 6.283185307179586476925286766559 * frequency / samplerate
	sine := math.sin(w0)
	cosine := math.cos(w0)
	alpha := sine / (2.0 * q_factor)
	a0, a1, a2 := 1.0 + alpha, -2.0 * cosine, 1.0 - alpha
	var b0, b1, b2: f64
	if kind == 0 {
		b0, b1, b2 = (1.0 - cosine) / 2.0, 1.0 - cosine, (1.0 - cosine) / 2.0
	} else if kind == 1 {
		b0, b1, b2 = (1.0 + cosine) / 2.0, -1.0 - cosine, (1.0 + cosine) / 2.0
	} else if kind == 2 {
		b0, b1, b2 = sine / 2.0, 0.0, -sine / 2.0
	} else if kind == 3 {
		b0, b1, b2 = 1.0 - alpha, -2.0 * cosine, 1.0 + alpha
		a0, a1, a2 = b2, b1, b0
	} else if kind == 4 {
		big_a := math.pow(10.0, gain_db / 40.0)
		b0, b1, b2 = 1.0 + alpha * big_a, -2.0 * cosine, 1.0 - alpha * big_a
		a0, a1, a2 = 1.0 + alpha / big_a, -2.0 * cosine, 1.0 - alpha / big_a
	} else if kind == 5 || kind == 6 {
		big_a := math.pow(10.0, gain_db / 40.0)
		pmc := (big_a + 1.0) - (big_a - 1.0) * cosine
		ppmc := (big_a + 1.0) + (big_a - 1.0) * cosine
		mpc := (big_a - 1.0) - (big_a + 1.0) * cosine
		pmpc := (big_a - 1.0) + (big_a + 1.0) * cosine
		aa2 := 2.0 * math.sqrt(big_a) * alpha
		if kind == 5 {
			b0, b1, b2 = big_a * (pmc + aa2), 2.0 * big_a * mpc, big_a * (pmc - aa2)
			a0, a1, a2 = ppmc + aa2, -2.0 * pmpc, ppmc - aa2
		} else {
			b0, b1, b2 = big_a * (ppmc + aa2), -2.0 * big_a * pmpc, big_a * (ppmc - aa2)
			a0, a1, a2 = pmc + aa2, 2.0 * mpc, pmc - aa2
		}
	} else if kind == 7 {
		b0, b1, b2 = 1.0, -2.0 * cosine, 1.0
	} else {
		b0, b1, b2 = alpha, 0.0, -alpha
	}
	return [6]f64{a0, a1, a2, b0, b1, b2}
}

@(export)
butterworth_filter :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 6 do return INVALID_RESULT
	kind, coefficient_index := values[0], values[1]
	frequency, samplerate := values[2], values[3]
	gain_milli_db, q_micro := values[4], values[5]
	if kind < 0 || kind > 8 || coefficient_index < 0 || coefficient_index > 5 ||
		frequency < 1 || frequency > 95999 || samplerate < 1 || samplerate > 192000 ||
		2 * frequency >= samplerate do return INVALID_RESULT
	if q_micro != -1 && (q_micro < 1 || q_micro > 10000000) do return INVALID_RESULT
	needs_gain := kind >= 4 && kind <= 6
	if needs_gain {
		if gain_milli_db < -60000 || gain_milli_db > 60000 do return INVALID_RESULT
	} else if gain_milli_db != 0 do return INVALID_RESULT
	gain_db := if needs_gain do f64(gain_milli_db) / 1000.0 else 0.0
	q_factor := if q_micro == -1 do 1.0 / math.sqrt(2.0) else f64(q_micro) / 1000000.0
	output := coefficients(kind, f64(frequency), f64(samplerate), gain_db, q_factor)
	return output[usize(coefficient_index)]
}
