package rodinia_leukocyte_gicov

import "core:c"

// Clean-room bounded GICOV recurrence; complete applicable notice is in package LICENSE.txt.
GICOV_ELLIPSES :: 7
GICOV_MAX_POINTS :: 16
GICOV_INVALID :: f64 = -1.0e300

decode :: proc(raw: i64) -> f32 { return f32(raw) / 1_000_000.0 }

@(export)
rodinia_leukocyte_gicov :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 1 do return GICOV_INVALID
	if input[0] < 2 || input[0] > GICOV_MAX_POINTS do return GICOV_INVALID
	points := int(input[0])
	if length != c.size_t(1 + GICOV_ELLIPSES * points) do return GICOV_INVALID
	for i in 1 ..< int(length) do if input[i] < -1_000_000 || input[i] > 1_000_000 do return GICOV_INVALID

	maximum: f32 = 0
	for ellipse in 0 ..< GICOV_ELLIPSES {
		sum, mean, m2: f32 = 0, 0, 0
		base := 1 + ellipse * points
		for n in 0 ..< points {
			p := decode(input[base+n])
			sum = sum + p
			delta := p - mean
			mean = mean + delta / f32(n+1)
			m2 = m2 + delta * (p-mean)
		}
		mean = sum / f32(points)
		variance := m2 / f32(points-1)
		if !(variance > 0) do return GICOV_INVALID
		score := (mean*mean) / variance
		if score > maximum do maximum = score
	}
	return f64(maximum)
}
