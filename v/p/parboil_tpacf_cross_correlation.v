import math

const num_bins = 20
const max_points = 4
const max_input_length = 26
const pi_value = 3.141592653589793238462643383279502884

fn coordinate(input &i64, offset int) f32 {
	return f32(unsafe { input[offset] }) / f32(1000000.0)
}

/* Parboil TPACF, Illinois Open Source License; see package LICENSE.txt. */
@[export: 'parboil_tpacf_cross_correlation']
pub fn parboil_tpacf_cross_correlation(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 8 || input_length > max_input_length { return -1 }
	data_value := unsafe { input[0] }
	random_value := unsafe { input[1] }
	if data_value < 1 || data_value > max_points || random_value < 1 || random_value > max_points { return -1 }
	data_count := int(data_value)
	random_count := int(random_value)
	if input_length != usize(2 + 3 * (data_count + random_count)) { return -1 }
	unsafe {
		for i in 2 .. input_length {
			if input[i] < -1000000 || input[i] > 1000000 { return -1 }
		}
	}
	if unsafe { output == nil } || output_capacity < num_bins { return -2 }

	mut boundaries := [num_bins + 1]f32{}
	for k in 0 .. num_bins + 1 {
		exponent := math.log10(1.0) + f64(k) * 1.0 / 5.0
		arcminutes := math.pow(10.0, exponent)
		radians := arcminutes / 60.0 * (pi_value / 180.0)
		boundaries[k] = f32(math.cos(radians))
	}
	mut histogram := [num_bins]u8{}
	random_base := 2 + 3 * data_count
	for j in 0 .. random_count {
		rx := coordinate(input, random_base + 3 * j)
		ry := coordinate(input, random_base + 3 * j + 1)
		rz := coordinate(input, random_base + 3 * j + 2)
		for i in 0 .. data_count {
			dx := coordinate(input, 2 + 3 * i)
			dy := coordinate(input, 2 + 3 * i + 1)
			dz := coordinate(input, 2 + 3 * i + 2)
			px := dx * rx
			py := dy * ry
			pz := dz * rz
			xy := px + py
			distance := xy + pz
			mut min := 0
			mut max := num_bins
			for max > min + 1 {
				middle := (min + max) / 2
				if distance >= boundaries[middle] { max = middle } else { min = middle }
			}
			if distance < boundaries[min] && distance >= boundaries[max] { histogram[max - 1]++ }
		}
	}
	unsafe {
		for bin in 0 .. num_bins { output[bin] = histogram[bin] }
	}
	return num_bins
}
