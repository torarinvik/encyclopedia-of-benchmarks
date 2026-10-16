module softmax

import math

@[export: 'softmax']
pub fn softmax(values &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(values) || length < 1 || length > 64 { return -1 }
		for index in 0 .. int(length) {
			value := values[index]
			if value != value || value < -20.0 || value > 20.0 { return -1 }
		}
		if isnil(output) || capacity < length { return -2 }

		mut total := 0.0
		for index in 0 .. int(length) { total += math.exp(values[index]) }
		for index in 0 .. int(length) { output[index] = math.exp(values[index]) / total }
		return i64(length)
	}
}
