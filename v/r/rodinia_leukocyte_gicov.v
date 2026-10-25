module rodinia_leukocyte_gicov

// Clean-room bounded GICOV recurrence; complete applicable notice is in package LICENSE.txt.
const ellipse_count = 7
const max_points = 16
const invalid_result = -1.0e300

fn decode(raw i64) f32 { return f32(raw) / 1000000.0 }

@[export: 'rodinia_leukocyte_gicov']
pub fn rodinia_leukocyte_gicov(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 1 { return invalid_result }
	unsafe {
		if input[0] < 2 || input[0] > max_points { return invalid_result }
		points := int(input[0])
		if length != usize(1 + ellipse_count * points) { return invalid_result }
		for i := 1; i < int(length); i++ {
			if input[i] < -1000000 || input[i] > 1000000 { return invalid_result }
		}
		mut maximum := f32(0)
		for ellipse := 0; ellipse < ellipse_count; ellipse++ {
			mut sum := f32(0)
			mut mean := f32(0)
			mut m2 := f32(0)
			base := 1 + ellipse * points
			for n := 0; n < points; n++ {
				p := decode(input[base+n])
				sum = sum + p
				delta := p - mean
				mean = mean + delta / f32(n+1)
				m2 = m2 + delta * (p-mean)
			}
			mean = sum / f32(points)
			variance := m2 / f32(points-1)
			if !(variance > 0) { return invalid_result }
			score := (mean*mean) / variance
			if score > maximum { maximum = score }
		}
		return f64(maximum)
	}
}
