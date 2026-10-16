package particle_swarm_optimization

import "core:c"

PARTICLE_COUNT :: 50
DIMENSION_COUNT :: 5
ITERATION_COUNT :: 1000
MAX_INPUT_LENGTH :: 2
OUTPUT_VALUE_COUNT :: 1 + DIMENSION_COUNT + ITERATION_COUNT
OUTPUT_BYTES :: OUTPUT_VALUE_COUNT * 8

next_uniform :: proc "contextless" (state: ^u64) -> f64 {
	value := state^
	value = value ^ (value << 13)
	value = value ^ (value >> 7)
	value = value ^ (value << 17)
	state^ = value
	return f64(value >> 11) * 1.1102230246251565e-16
}

sphere :: proc "contextless" (point: [^]f64) -> f64 {
	cost := 0.0
	for coordinate := 0; coordinate < DIMENSION_COUNT; coordinate += 1 {
		cost += point[coordinate] * point[coordinate]
	}
	return cost
}

write_f64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + c.size_t(byte)] = u8(bits >> u64(8 * byte))
	}
}

@(export)
particle_swarm_optimization :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) || length != 1 || input[0] <= 0 do return -1
	if output == nil || output_capacity < c.size_t(OUTPUT_BYTES) do return -2

	random_state := u64(input[0])
	position: [PARTICLE_COUNT][DIMENSION_COUNT]f64
	velocity: [PARTICLE_COUNT][DIMENSION_COUNT]f64
	personal_position: [PARTICLE_COUNT][DIMENSION_COUNT]f64
	personal_cost: [PARTICLE_COUNT]f64
	global_position: [DIMENSION_COUNT]f64
	history: [ITERATION_COUNT]f64
	for coordinate := 0; coordinate < DIMENSION_COUNT; coordinate += 1 {
		global_position[coordinate] = 0.0
	}
	global_cost := 1.7976931348623157e308

	for particle := 0; particle < PARTICLE_COUNT; particle += 1 {
		for coordinate := 0; coordinate < DIMENSION_COUNT; coordinate += 1 {
			position[particle][coordinate] = -10.0 + 20.0 * next_uniform(&random_state)
			velocity[particle][coordinate] = 0.0
			personal_position[particle][coordinate] = position[particle][coordinate]
		}
		personal_cost[particle] = sphere(&position[particle][0])
		if personal_cost[particle] < global_cost {
			global_cost = personal_cost[particle]
			for coordinate := 0; coordinate < DIMENSION_COUNT; coordinate += 1 {
				global_position[coordinate] = personal_position[particle][coordinate]
			}
		}
	}

	inertia := 1.0
	for iteration := 0; iteration < ITERATION_COUNT; iteration += 1 {
		for particle := 0; particle < PARTICLE_COUNT; particle += 1 {
			personal_random: [DIMENSION_COUNT]f64
			social_random: [DIMENSION_COUNT]f64
			for coordinate := 0; coordinate < DIMENSION_COUNT; coordinate += 1 {
				personal_random[coordinate] = next_uniform(&random_state)
			}
			for coordinate := 0; coordinate < DIMENSION_COUNT; coordinate += 1 {
				social_random[coordinate] = next_uniform(&random_state)
			}

			for coordinate := 0; coordinate < DIMENSION_COUNT; coordinate += 1 {
				cognitive := (2.0 * personal_random[coordinate]) *
					(personal_position[particle][coordinate] - position[particle][coordinate])
				social := (2.0 * social_random[coordinate]) *
					(global_position[coordinate] - position[particle][coordinate])
				velocity[particle][coordinate] = inertia * velocity[particle][coordinate] + cognitive + social
				position[particle][coordinate] += velocity[particle][coordinate]
			}

			cost := sphere(&position[particle][0])
			if cost < personal_cost[particle] {
				personal_cost[particle] = cost
				for coordinate := 0; coordinate < DIMENSION_COUNT; coordinate += 1 {
					personal_position[particle][coordinate] = position[particle][coordinate]
				}
				if personal_cost[particle] < global_cost {
					global_cost = personal_cost[particle]
					for coordinate := 0; coordinate < DIMENSION_COUNT; coordinate += 1 {
						global_position[coordinate] = personal_position[particle][coordinate]
					}
				}
			}
		}
		history[iteration] = global_cost
		inertia *= 0.99
	}

	offset := c.size_t(0)
	write_f64_le(output, offset, global_cost)
	offset += 8
	for coordinate := 0; coordinate < DIMENSION_COUNT; coordinate += 1 {
		write_f64_le(output, offset, global_position[coordinate])
		offset += 8
	}
	for iteration := 0; iteration < ITERATION_COUNT; iteration += 1 {
		write_f64_le(output, offset, history[iteration])
		offset += 8
	}
	return i64(OUTPUT_BYTES)
}
