module splash2_water_nsquared

const max_n = 64
const max_parseable = 260
const max_output_words = 194
const scale = i64(1_000_000)

fn trunc_div(numerator i64, denominator i64) i64 {
	if numerator < 0 { return -((-numerator) / denominator) }
	return numerator / denominator
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
	}
}

@[export: 'splash2_water_nsquared']
pub fn splash2_water_nsquared(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 3 || length > usize(max_parseable) { return -1 }
	unsafe {
		if input == nil { return -1 }
		n_raw := input[0]
		grid := input[1]
		radius := input[2]
		if n_raw < 0 || n_raw > max_n || grid < 1 || grid > 8 || radius < 1 || radius > 4 { return -1 }
		n := int(n_raw)
		if length != usize(3 + 4 * n) { return -1 }
		side := grid * radius
		radius2 := radius * radius
		mut x := [max_n]i64{}
		mut y := [max_n]i64{}
		mut z := [max_n]i64{}
		mut charge := [max_n]i64{}
		for i in 0 .. n {
			at := 3 + 4 * i
			x[i] = input[at]; y[i] = input[at + 1]; z[i] = input[at + 2]; charge[i] = input[at + 3]
			if x[i] < 0 || x[i] >= side || y[i] < 0 || y[i] >= side || z[i] < 0 || z[i] >= side || charge[i] < -4 || charge[i] > 4 { return -1 }
		}
		mut force := [max_n][3]i64{}
		mut energy := i64(0)
		mut pairs := i64(0)
		for i in 0 .. n {
			for j in i + 1 .. n {
				dx := x[j] - x[i]; dy := y[j] - y[i]; dz := z[j] - z[i]
				r2 := dx * dx + dy * dy + dz * dz
				if r2 >= radius2 { continue }
				product := charge[i] * charge[j]
				energy += trunc_div(product * (radius2 - r2) * scale, (1 + r2) * (1 + radius2))
				denominator := (1 + r2) * (1 + r2)
				fx := trunc_div(-2 * product * dx * scale, denominator)
				fy := trunc_div(-2 * product * dy * scale, denominator)
				fz := trunc_div(-2 * product * dz * scale, denominator)
				force[i][0] += fx; force[i][1] += fy; force[i][2] += fz
				force[j][0] -= fx; force[j][1] -= fy; force[j][2] -= fz
				pairs++
			}
		}
		words := 3 * n + 2
		bytes := 8 * words
		if output == nil || capacity < usize(bytes) { return -2 }
		mut result := [max_output_words]i64{}
		for i in 0 .. n { for axis in 0 .. 3 { result[3 * i + axis] = force[i][axis] } }
		result[3 * n] = energy; result[3 * n + 1] = pairs
		for word in 0 .. words { store_le(mut output, word * 8, result[word]) }
		return i64(bytes)
	}
}
