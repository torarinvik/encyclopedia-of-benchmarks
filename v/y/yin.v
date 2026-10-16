module yin

const invalid_result = -1.0e300

@[export: 'yin']
pub fn yin(input &i64, length usize) f64 {
	if length < 7 || length > 261 { return invalid_result }
	count_v := unsafe { input[0] }
	rate := unsafe { input[1] }
	min_hz := unsafe { input[2] }
	max_hz := unsafe { input[3] }
	threshold := unsafe { input[4] }
	if count_v < 2 || count_v > 256 || length != usize(5 + count_v) || rate < 1 || rate > 192000 || min_hz < 1 || max_hz <= min_hz || max_hz > rate / 2 || threshold < 1 || threshold > 999999 { return invalid_result }
	count := int(count_v)
	for i in 0 .. count {
		if unsafe { input[5+i] } < -32768 || unsafe { input[5+i] } > 32767 { return invalid_result }
	}
	min_lag_v := rate / max_hz
	max_lag_v := rate / min_hz
	mut allowed := i64(64)
	if i64(count-1) < allowed { allowed = i64(count-1) }
	if min_lag_v < 1 || min_lag_v > max_lag_v || max_lag_v > allowed { return invalid_result }
	min_lag := int(min_lag_v)
	max_lag := int(max_lag_v)
	mut cmndf := []f64{len: 65, init: 1.0}
	mut running := f64(0)
	for lag in 1 .. max_lag + 1 {
		mut sum := f64(0)
		for i in 0 .. count-lag {
			delta := f64(unsafe { input[5+i] }) - f64(unsafe { input[5+i+lag] })
			sum += delta * delta
		}
		running += sum
		cmndf[lag] = sum * f64(lag) / (if running == 0.0 {1.0e-10} else {running})
	}
	threshold_f := f64(threshold) / 1_000_000.0
	mut lag := min_lag
	for lag <= max_lag && !(cmndf[lag] < threshold_f) { lag++ }
	if lag > max_lag { return invalid_result }
	for lag < max_lag && cmndf[lag+1] < cmndf[lag] { lag++ }
	left := if lag > 1 {lag-1} else {lag}
	right := if lag < max_lag {lag+1} else {lag}
	denominator := cmndf[left] - 2.0 * cmndf[lag] + cmndf[right]
	offset := if denominator == 0.0 {0.0} else {(cmndf[left] - cmndf[right]) / (2.0 * denominator)}
	refined := f64(lag) + offset
	if !(refined > 0.0) { return invalid_result }
	return f64(rate) / refined
}
