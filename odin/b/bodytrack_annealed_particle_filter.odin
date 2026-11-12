package bodytrack_annealed_particle_filter

import "core:c"

max_d :: 4
max_n :: 16
max_l :: 4
max_input :: 318
q24 :: i64(16_777_216)

round_away :: proc(numerator, denominator: i64) -> i64 {
	magnitude := numerator
	if magnitude < 0 { magnitude = -magnitude }
	quotient := magnitude / denominator
	remainder := magnitude % denominator
	if 2 * remainder >= denominator { quotient += 1 }
	if numerator < 0 { return -quotient }
	return quotient
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> (8 * byte)) & 255)
	}
}

@(export)
bodytrack_annealed_particle_filter :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > max_input { return -1 }
	d_value, n_value, layers_value := input[0], input[1], input[2]
	if d_value < 1 || d_value > max_d || n_value < 2 || n_value > max_n ||
			layers_value < 1 || layers_value > max_l { return -1 }
	d, n, layers := int(d_value), int(n_value), int(layers_value)
	expected := 2 + d + 2 * layers + n * d + (layers - 1) * n * (d + 1)
	if int(length) != expected { return -1 }

	target_at := 3
	beta_at := target_at + d
	sigma_at := beta_at + layers
	pose_at := sigma_at + layers - 1
	uniform_at := pose_at + n * d
	shock_at := uniform_at + (layers - 1) * n
	var target: [max_d]i64
	var beta: [max_l]i64
	var sigma: [max_l - 1]i64
	for axis := 0; axis < d; axis += 1 {
		target[axis] = input[target_at+axis]
		if target[axis] < -10000 || target[axis] > 10000 { return -1 }
	}
	for layer := 0; layer < layers; layer += 1 {
		beta[layer] = input[beta_at+layer]
		if beta[layer] < 1 || beta[layer] > 8 || (layer > 0 && beta[layer] <= beta[layer-1]) { return -1 }
	}
	for layer := 0; layer < layers-1; layer += 1 {
		sigma[layer] = input[sigma_at+layer]
		if sigma[layer] < 0 || sigma[layer] > 2000 || (layer > 0 && sigma[layer] > sigma[layer-1]) { return -1 }
	}
	for item := 0; item < n*d; item += 1 {
		if input[pose_at+item] < -10000 || input[pose_at+item] > 10000 { return -1 }
	}
	for item := 0; item < (layers-1)*n; item += 1 {
		if input[uniform_at+item] < 0 || input[uniform_at+item] >= q24 { return -1 }
	}
	for item := 0; item < (layers-1)*n*d; item += 1 {
		if input[shock_at+item] < -3000 || input[shock_at+item] > 3000 { return -1 }
	}

	required := 8 * d
	if output == nil || capacity < c.size_t(required) { return -2 }
	var population: [2][max_n][max_d]i64
	var weights: [max_n]i64
	var estimate: [max_d]i64
	for particle := 0; particle < n; particle += 1 {
		for axis := 0; axis < d; axis += 1 { population[0][particle][axis] = input[pose_at+particle*d+axis] }
	}
	active := 0
	for layer := 0; layer < layers; layer += 1 {
		total_weight := i64(0)
		for particle := 0; particle < n; particle += 1 {
			squared_distance := i64(0)
			for axis := 0; axis < d; axis += 1 {
				delta := population[active][particle][axis] - target[axis]
				squared_distance += delta * delta
			}
			energy := squared_distance / 10000
			base := q24 * 100000 / (100000 + energy)
			weight := base
			for power := i64(1); power < beta[layer]; power += 1 { weight = weight * base / q24 }
			weights[particle] = weight
			total_weight += weight
		}
		if layer+1 == layers {
			for axis := 0; axis < d; axis += 1 {
				moment := i64(0)
				for particle := 0; particle < n; particle += 1 { moment += weights[particle] * population[active][particle][axis] }
				estimate[axis] = round_away(moment, total_weight)
			}
			break
		}
		destination := 1 - active
		for child := 0; child < n; child += 1 {
			draw := input[uniform_at+layer*n+child]
			threshold := draw * total_weight / q24
			cumulative := i64(0)
			ancestor := 0
			for cumulative <= threshold { cumulative += weights[ancestor]; ancestor += 1 }
			ancestor -= 1
			for axis := 0; axis < d; axis += 1 {
				shock := input[shock_at+layer*n*d+child*d+axis]
				movement := round_away(sigma[layer]*shock, 1000)
				coordinate := population[active][ancestor][axis] + movement
				if coordinate < -10000 { coordinate = -10000 }
				if coordinate > 10000 { coordinate = 10000 }
				population[destination][child][axis] = coordinate
			}
		}
		active = destination
	}
	for axis := 0; axis < d; axis += 1 { put_i64_le(output, 8*axis, estimate[axis]) }
	return i64(required)
}
