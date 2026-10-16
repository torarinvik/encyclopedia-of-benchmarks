const PARTICLE_COUNT: usize = 50;
const DIMENSION_COUNT: usize = 5;
const ITERATION_COUNT: usize = 1000;
const MAX_INPUT_LENGTH: usize = 2;
const OUTPUT_VALUE_COUNT: usize = 1 + DIMENSION_COUNT + ITERATION_COUNT;
const OUTPUT_BYTES: usize = OUTPUT_VALUE_COUNT * 8;

fn next_uniform(state: &mut u64) -> f64 {
    *state ^= *state << 13;
    *state ^= *state >> 7;
    *state ^= *state << 17;
    ((*state >> 11) as f64) * (1.0 / 9007199254740992.0)
}

fn sphere(point: &[f64; DIMENSION_COUNT]) -> f64 {
    let mut cost = 0.0;
    for coordinate in 0..DIMENSION_COUNT {
        cost += point[coordinate] * point[coordinate];
    }
    cost
}

unsafe fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bytes = value.to_le_bytes();
    for byte in 0..8 {
        *output.add(offset + byte) = bytes[byte];
    }
}

#[no_mangle]
pub unsafe extern "C" fn particle_swarm_optimization(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH || length != 1 || *input <= 0 {
        return -1;
    }
    if output.is_null() || output_capacity < OUTPUT_BYTES {
        return -2;
    }

    let mut random_state = *input as u64;
    let mut position = [[0.0; DIMENSION_COUNT]; PARTICLE_COUNT];
    let mut velocity = [[0.0; DIMENSION_COUNT]; PARTICLE_COUNT];
    let mut personal_position = [[0.0; DIMENSION_COUNT]; PARTICLE_COUNT];
    let mut personal_cost = [0.0; PARTICLE_COUNT];
    let mut global_position = [0.0; DIMENSION_COUNT];
    let mut history = [0.0; ITERATION_COUNT];
    let mut global_cost = f64::MAX;

    for particle in 0..PARTICLE_COUNT {
        for coordinate in 0..DIMENSION_COUNT {
            position[particle][coordinate] = -10.0 + 20.0 * next_uniform(&mut random_state);
            personal_position[particle][coordinate] = position[particle][coordinate];
        }
        personal_cost[particle] = sphere(&position[particle]);
        if personal_cost[particle] < global_cost {
            global_cost = personal_cost[particle];
            global_position = personal_position[particle];
        }
    }

    let mut inertia = 1.0;
    for iteration in 0..ITERATION_COUNT {
        for particle in 0..PARTICLE_COUNT {
            let mut personal_random = [0.0; DIMENSION_COUNT];
            let mut social_random = [0.0; DIMENSION_COUNT];
            for coordinate in 0..DIMENSION_COUNT {
                personal_random[coordinate] = next_uniform(&mut random_state);
            }
            for coordinate in 0..DIMENSION_COUNT {
                social_random[coordinate] = next_uniform(&mut random_state);
            }

            for coordinate in 0..DIMENSION_COUNT {
                let cognitive = (2.0 * personal_random[coordinate])
                    * (personal_position[particle][coordinate] - position[particle][coordinate]);
                let social = (2.0 * social_random[coordinate])
                    * (global_position[coordinate] - position[particle][coordinate]);
                velocity[particle][coordinate] = inertia * velocity[particle][coordinate] + cognitive + social;
                position[particle][coordinate] += velocity[particle][coordinate];
            }

            let cost = sphere(&position[particle]);
            if cost < personal_cost[particle] {
                personal_cost[particle] = cost;
                personal_position[particle] = position[particle];
                if personal_cost[particle] < global_cost {
                    global_cost = personal_cost[particle];
                    global_position = personal_position[particle];
                }
            }
        }
        history[iteration] = global_cost;
        inertia *= 0.99;
    }

    let mut offset = 0;
    write_f64_le(output, offset, global_cost);
    offset += 8;
    for value in global_position {
        write_f64_le(output, offset, value);
        offset += 8;
    }
    for value in history {
        write_f64_le(output, offset, value);
        offset += 8;
    }
    OUTPUT_BYTES as i64
}
