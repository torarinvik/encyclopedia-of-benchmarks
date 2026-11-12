module bodytrack_annealed_particle_filter

const max_d = 4
const max_n = 16
const max_l = 4
const max_input = 318
const q24 = i64(16_777_216)

fn round_away(numerator i64, denominator i64) i64 {
	magnitude := if numerator < 0 { -numerator } else { numerator }
	mut quotient := magnitude / denominator
	remainder := magnitude % denominator
	if 2 * remainder >= denominator { quotient++ }
	return if numerator < 0 { -quotient } else { quotient }
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'bodytrack_annealed_particle_filter']
pub fn bodytrack_annealed_particle_filter(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > usize(max_input) { return -1 }
		d_value, n_value, layers_value := input[0], input[1], input[2]
		if d_value < 1 || d_value > max_d || n_value < 2 || n_value > max_n || layers_value < 1 || layers_value > max_l { return -1 }
		d, n, layers := int(d_value), int(n_value), int(layers_value)
		expected := 2 + d + 2 * layers + n * d + (layers - 1) * n * (d + 1)
		if length != usize(expected) { return -1 }
		target_at := 3
		beta_at := target_at + d
		sigma_at := beta_at + layers
		pose_at := sigma_at + layers - 1
		uniform_at := pose_at + n * d
		shock_at := uniform_at + (layers - 1) * n
		mut target := [max_d]i64{}
		mut beta := [max_l]i64{}
		mut sigma := [max_l - 1]i64{}
		for axis in 0 .. d {
			target[axis] = input[target_at + axis]
			if target[axis] < -10000 || target[axis] > 10000 { return -1 }
		}
		for layer in 0 .. layers {
			beta[layer] = input[beta_at + layer]
			if beta[layer] < 1 || beta[layer] > 8 || (layer > 0 && beta[layer] <= beta[layer - 1]) { return -1 }
		}
		for layer in 0 .. layers - 1 {
			sigma[layer] = input[sigma_at + layer]
			if sigma[layer] < 0 || sigma[layer] > 2000 || (layer > 0 && sigma[layer] > sigma[layer - 1]) { return -1 }
		}
		for item in 0 .. n * d {
			if input[pose_at + item] < -10000 || input[pose_at + item] > 10000 { return -1 }
		}
		for item in 0 .. (layers - 1) * n {
			if input[uniform_at + item] < 0 || input[uniform_at + item] >= q24 { return -1 }
		}
		for item in 0 .. (layers - 1) * n * d {
			if input[shock_at + item] < -3000 || input[shock_at + item] > 3000 { return -1 }
		}
		required := 8 * d
		if output == nil || capacity < usize(required) { return -2 }
		mut population := [2][max_n][max_d]i64{}
		mut weights := [max_n]i64{}
		mut estimate := [max_d]i64{}
		for particle in 0 .. n {
			for axis in 0 .. d { population[0][particle][axis] = input[pose_at + particle * d + axis] }
		}
		mut active := 0
		for layer in 0 .. layers {
			mut total_weight := i64(0)
			for particle in 0 .. n {
				mut squared_distance := i64(0)
				for axis in 0 .. d {
					delta := population[active][particle][axis] - target[axis]
					squared_distance += delta * delta
				}
				energy := squared_distance / 10000
				base := q24 * 100000 / (100000 + energy)
				mut weight := base
				for power in 1 .. int(beta[layer]) { weight = weight * base / q24 }
				weights[particle] = weight
				total_weight += weight
			}
			if layer + 1 == layers {
				for axis in 0 .. d {
					mut moment := i64(0)
					for particle in 0 .. n { moment += weights[particle] * population[active][particle][axis] }
					estimate[axis] = round_away(moment, total_weight)
				}
				break
			}
			destination := 1 - active
			for child in 0 .. n {
				threshold := input[uniform_at + layer * n + child] * total_weight / q24
				mut cumulative := i64(0)
				mut ancestor := 0
				for cumulative <= threshold { cumulative += weights[ancestor]; ancestor++ }
				ancestor--
				for axis in 0 .. d {
					shock := input[shock_at + layer * n * d + child * d + axis]
					movement := round_away(sigma[layer] * shock, 1000)
					coordinate := population[active][ancestor][axis] + movement
					if coordinate < -10000 { coordinate = -10000 }
					if coordinate > 10000 { coordinate = 10000 }
					population[destination][child][axis] = coordinate
				}
			}
			active = destination
		}
		for axis in 0 .. d { put_i64_le(mut output, 8 * axis, estimate[axis]) }
		return i64(required)
	}
}
