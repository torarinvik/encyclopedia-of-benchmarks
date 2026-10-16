module interquartile_range

@[export: 'interquartile_range']
pub fn interquartile_range(values &i64, length usize) f64 {
	if length < 2 || length > 64 || unsafe { values == nil } { return -1.0e300 }
	unsafe {
		mut sorted := [64]i64{}
		for i in 0 .. length {
			if values[i] < -1000000 || values[i] > 1000000 { return -1.0e300 }
			sorted[i] = values[i]
		}
		for i in 1 .. length {
			key := sorted[i]
			mut j := i
			for j > 0 && sorted[j - 1] > key { sorted[j] = sorted[j - 1]; j-- }
			sorted[j] = key
		}
		half := int(length / 2)
		upper_start := half + int(length % 2)
		return median_i64(&sorted[upper_start], half) - median_i64(&sorted[0], half)
	}
}

fn median_i64(values &i64, count int) f64 {
	unsafe {
		if count % 2 != 0 { return f64(values[count / 2]) }
		return (f64(values[count / 2 - 1]) + f64(values[count / 2])) / 2.0
	}
}
