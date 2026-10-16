module particle_swarm_optimization

import math

const particle_count = 50
const dimension_count = 5
const iteration_count = 1000
const max_input_length = 2
const output_value_count = 1 + dimension_count + iteration_count
const output_bytes = output_value_count * 8

fn next_uniform(mut state &u64) f64 {
	unsafe {
		mut value := state[0]
		value ^= value << 13
		value ^= value >> 7
		value ^= value << 17
		state[0] = value
		return f64(value >> 11) * 1.1102230246251565e-16
	}
}

fn sphere(point &f64) f64 {
	mut cost := 0.0
	for coordinate in 0 .. dimension_count {
		cost += point[coordinate] * point[coordinate]
	}
	return cost
}

fn write_f64_le(mut output &u8, offset usize, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'particle_swarm_optimization']
pub fn particle_swarm_optimization(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length || length != 1 || unsafe { input[0] <= 0 } {
		return -1
	}
	if unsafe { output == nil } || output_capacity < output_bytes { return -2 }

	mut random_state := u64(unsafe { input[0] })
	mut positions := [particle_count][dimension_count]f64{}
	mut velocities := [particle_count][dimension_count]f64{}
	mut personal_positions := [particle_count][dimension_count]f64{}
	mut personal_costs := [particle_count]f64{}
	mut global_position := [dimension_count]f64{}
	mut history := [iteration_count]f64{}
	mut global_cost := 1.7976931348623157e308

	for particle in 0 .. particle_count {
		for coordinate in 0 .. dimension_count {
			positions[particle][coordinate] = -10.0 + 20.0 * next_uniform(mut random_state)
			personal_positions[particle][coordinate] = positions[particle][coordinate]
		}
		personal_costs[particle] = sphere(&positions[particle][0])
		if personal_costs[particle] < global_cost {
			global_cost = personal_costs[particle]
			for coordinate in 0 .. dimension_count {
				global_position[coordinate] = personal_positions[particle][coordinate]
			}
		}
	}

	mut inertia := 1.0
	for iteration in 0 .. iteration_count {
		for particle in 0 .. particle_count {
			mut personal_random := [dimension_count]f64{}
			mut social_random := [dimension_count]f64{}
			for coordinate in 0 .. dimension_count {
				personal_random[coordinate] = next_uniform(mut random_state)
			}
			for coordinate in 0 .. dimension_count {
				social_random[coordinate] = next_uniform(mut random_state)
			}

			for coordinate in 0 .. dimension_count {
				cognitive := (2.0 * personal_random[coordinate]) *
					(personal_positions[particle][coordinate] - positions[particle][coordinate])
				social := (2.0 * social_random[coordinate]) *
					(global_position[coordinate] - positions[particle][coordinate])
				velocities[particle][coordinate] = inertia * velocities[particle][coordinate] + cognitive + social
				positions[particle][coordinate] += velocities[particle][coordinate]
			}

			cost := sphere(&positions[particle][0])
			if cost < personal_costs[particle] {
				personal_costs[particle] = cost
				for coordinate in 0 .. dimension_count {
					personal_positions[particle][coordinate] = positions[particle][coordinate]
				}
				if personal_costs[particle] < global_cost {
					global_cost = personal_costs[particle]
					for coordinate in 0 .. dimension_count {
						global_position[coordinate] = personal_positions[particle][coordinate]
					}
				}
			}
		}
		history[iteration] = global_cost
		inertia *= 0.99
	}

	mut offset := usize(0)
	write_f64_le(mut output, offset, global_cost)
	offset += 8
	for coordinate in 0 .. dimension_count {
		write_f64_le(mut output, offset, global_position[coordinate])
		offset += 8
	}
	for iteration in 0 .. iteration_count {
		write_f64_le(mut output, offset, history[iteration])
		offset += 8
	}
	return i64(output_bytes)
}
