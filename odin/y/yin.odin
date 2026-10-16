package yin

import "core:c"

INVALID_RESULT :: f64(-1.0e300)

@(export)
yin :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 7 || length > 261 do return INVALID_RESULT
	count_v, rate, min_hz, max_hz, threshold := input[0], input[1], input[2], input[3], input[4]
	if count_v < 2 || count_v > 256 || length != c.size_t(5 + count_v) || rate < 1 || rate > 192000 || min_hz < 1 || max_hz <= min_hz || max_hz > rate / 2 || threshold < 1 || threshold > 999999 do return INVALID_RESULT
	count := int(count_v)
	for i in 0..<count {
		if input[5+i] < -32768 || input[5+i] > 32767 do return INVALID_RESULT
	}
	min_lag_v, max_lag_v := rate / max_hz, rate / min_hz
	allowed := min(i64(64), i64(count - 1))
	if min_lag_v < 1 || min_lag_v > max_lag_v || max_lag_v > allowed do return INVALID_RESULT
	min_lag, max_lag := int(min_lag_v), int(max_lag_v)
	cmndf: [65]f64
	for i in 0..<65 { cmndf[i] = 1.0 }
	running := f64(0)
	for lag in 1..=max_lag {
		sum := f64(0)
		for i in 0..<(count-lag) {
			delta := f64(input[5+i]) - f64(input[5+i+lag])
			sum += delta * delta
		}
		running += sum
		denom := running
		if running == 0 { denom = 1.0e-10 }
		cmndf[lag] = sum * f64(lag) / denom
	}
	threshold_f := f64(threshold) / 1_000_000.0
	lag := min_lag
	for lag <= max_lag && !(cmndf[lag] < threshold_f) { lag += 1 }
	if lag > max_lag do return INVALID_RESULT
	for lag < max_lag && cmndf[lag+1] < cmndf[lag] { lag += 1 }
	left := lag
	if lag > 1 { left = lag - 1 }
	right := lag
	if lag < max_lag { right = lag + 1 }
	denominator := cmndf[left] - 2.0*cmndf[lag] + cmndf[right]
	offset := f64(0)
	if denominator != 0 { offset = (cmndf[left]-cmndf[right])/(2.0*denominator) }
	refined := f64(lag) + offset
	if !(refined > 0) do return INVALID_RESULT
	return f64(rate) / refined
}
