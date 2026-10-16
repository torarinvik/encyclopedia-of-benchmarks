module verlet

@[export: 'verlet']
pub fn verlet(values &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(values) || length != 4 { return -1 }
		for i in 0 .. 4 {
			if values[i] != values[i] { return -1 }
		}
		if values[0] < 2.0 || values[0] > 32.0 || values[0] != f64(int(values[0])) ||
			values[1] < -1.0 || values[1] > 1.0 ||
			values[2] < -1.0 || values[2] > 1.0 ||
			values[3] < 0.0 || values[3] > 4.0 || values[3] != f64(int(values[3])) { return -1 }

		n := int(values[0])
		code := int(values[3])
		mut dt := 0.00390625
		if code == 1 { dt = 0.0078125 }
		else if code == 2 { dt = 0.015625 }
		else if code == 3 { dt = 0.03125 }
		else if code == 4 { dt = 0.0625 }
		dt_squared := dt * dt
		if isnil(output) || capacity < usize(2 * n) { return -2 }

		output[0] = values[1]
		output[1] = values[1] + values[2] * dt + 0.5 * (-values[1]) * dt_squared
		for i in 1 .. n - 1 {
			output[i + 1] = 2.0 * output[i] - output[i - 1] + (-output[i]) * dt_squared
		}
		for i in 0 .. n {
			output[n + i] = f64(i) * dt
		}
		return i64(2 * n)
	}
}
