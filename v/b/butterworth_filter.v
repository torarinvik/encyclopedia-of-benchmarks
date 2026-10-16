module butterworth_filter

import math

const invalid_result = -1.0e300

fn coefficients(kind i64, frequency f64, samplerate f64, gain_db f64, q_factor f64) [6]f64 {
	w0 := 6.283185307179586476925286766559 * frequency / samplerate
	sine := math.sin(w0)
	cosine := math.cos(w0)
	alpha := sine / (2.0 * q_factor)
	mut a0 := 1.0 + alpha
	mut a1 := -2.0 * cosine
	mut a2 := 1.0 - alpha
	mut b0 := f64(0)
	mut b1 := f64(0)
	mut b2 := f64(0)
	if kind == 0 {
		b0 = (1.0 - cosine) / 2.0; b1 = 1.0 - cosine; b2 = b0
	} else if kind == 1 {
		b0 = (1.0 + cosine) / 2.0; b1 = -1.0 - cosine; b2 = b0
	} else if kind == 2 {
		b0 = sine / 2.0; b1 = 0.0; b2 = -b0
	} else if kind == 3 {
		b0 = 1.0 - alpha; b1 = -2.0 * cosine; b2 = 1.0 + alpha
		a0 = b2; a1 = b1; a2 = b0
	} else if kind == 4 {
		big_a := math.pow(10.0, gain_db / 40.0)
		b0 = 1.0 + alpha * big_a; b1 = -2.0 * cosine; b2 = 1.0 - alpha * big_a
		a0 = 1.0 + alpha / big_a; a1 = -2.0 * cosine; a2 = 1.0 - alpha / big_a
	} else if kind == 5 || kind == 6 {
		big_a := math.pow(10.0, gain_db / 40.0)
		pmc := (big_a + 1.0) - (big_a - 1.0) * cosine
		ppmc := (big_a + 1.0) + (big_a - 1.0) * cosine
		mpc := (big_a - 1.0) - (big_a + 1.0) * cosine
		pmpc := (big_a - 1.0) + (big_a + 1.0) * cosine
		aa2 := 2.0 * math.sqrt(big_a) * alpha
		if kind == 5 {
			b0 = big_a * (pmc + aa2); b1 = 2.0 * big_a * mpc; b2 = big_a * (pmc - aa2)
			a0 = ppmc + aa2; a1 = -2.0 * pmpc; a2 = ppmc - aa2
		} else {
			b0 = big_a * (ppmc + aa2); b1 = -2.0 * big_a * pmpc; b2 = big_a * (ppmc - aa2)
			a0 = pmc + aa2; a1 = 2.0 * mpc; a2 = pmc - aa2
		}
	} else if kind == 7 {
		b0 = 1.0; b1 = -2.0 * cosine; b2 = 1.0
	} else {
		b0 = alpha; b1 = 0.0; b2 = -alpha
	}
	return [a0, a1, a2, b0, b1, b2]
}

@[export: 'butterworth_filter']
pub fn butterworth_filter(values &i64, length usize) f64 {
	if length != 6 { return invalid_result }
	unsafe {
		if values == nil { return invalid_result }
		kind := values[0]
		coefficient_index := values[1]
		frequency := values[2]
		samplerate := values[3]
		gain_milli_db := values[4]
		q_micro := values[5]
		if kind < 0 || kind > 8 || coefficient_index < 0 || coefficient_index > 5 ||
			frequency < 1 || frequency > 95999 || samplerate < 1 || samplerate > 192000 ||
			2 * frequency >= samplerate { return invalid_result }
		if q_micro != -1 && (q_micro < 1 || q_micro > 10000000) { return invalid_result }
		needs_gain := kind >= 4 && kind <= 6
		if needs_gain {
			if gain_milli_db < -60000 || gain_milli_db > 60000 { return invalid_result }
		} else if gain_milli_db != 0 { return invalid_result }
		gain_db := if needs_gain { f64(gain_milli_db) / 1000.0 } else { 0.0 }
		q_factor := if q_micro == -1 { 1.0 / math.sqrt(2.0) } else { f64(q_micro) / 1000000.0 }
		output := coefficients(kind, f64(frequency), f64(samplerate), gain_db, q_factor)
		return output[int(coefficient_index)]
	}
}
