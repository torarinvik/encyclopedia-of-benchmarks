module particle_swarm_optimization;

const usz PARTICLE_COUNT = 50;
const usz DIMENSION_COUNT = 5;
const usz ITERATION_COUNT = 1000;
const usz MAX_INPUT_LENGTH = 2;
const usz OUTPUT_VALUE_COUNT = 1 + DIMENSION_COUNT + ITERATION_COUNT;
const usz OUTPUT_BYTES = OUTPUT_VALUE_COUNT * 8;

fn double next_uniform(ulong* state) {
    ulong value = state[0];
    value ^= value << 13;
    value ^= value >> 7;
    value ^= value << 17;
    state[0] = value;
    return (double)(value >> 11) * 1.1102230246251565e-16;
}

fn double sphere(double* point) {
    double cost = 0.0;
    for (usz coordinate = 0; coordinate < DIMENSION_COUNT; coordinate++)
        cost += point[coordinate] * point[coordinate];
    return cost;
}

fn void write_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long particle_swarm_optimization(long* input, usz length, char* output,
                                    usz output_capacity) @export("particle_swarm_optimization") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH || length != 1 || input[0] <= 0)
        return -1;
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;

    ulong random_state = (ulong)input[0];
    double[PARTICLE_COUNT][DIMENSION_COUNT] position;
    double[PARTICLE_COUNT][DIMENSION_COUNT] velocity;
    double[PARTICLE_COUNT][DIMENSION_COUNT] personal_position;
    double[PARTICLE_COUNT] personal_cost;
    double[DIMENSION_COUNT] global_position;
    double[ITERATION_COUNT] history;
    for (usz coordinate = 0; coordinate < DIMENSION_COUNT; coordinate++) global_position[coordinate] = 0.0;
    double global_cost = 1.7976931348623157e308;

    for (usz particle = 0; particle < PARTICLE_COUNT; particle++) {
        for (usz coordinate = 0; coordinate < DIMENSION_COUNT; coordinate++) {
            position[particle][coordinate] = -10.0 + 20.0 * next_uniform(&random_state);
            velocity[particle][coordinate] = 0.0;
            personal_position[particle][coordinate] = position[particle][coordinate];
        }
        personal_cost[particle] = sphere(&position[particle][0]);
        if (personal_cost[particle] < global_cost) {
            global_cost = personal_cost[particle];
            for (usz coordinate = 0; coordinate < DIMENSION_COUNT; coordinate++)
                global_position[coordinate] = personal_position[particle][coordinate];
        }
    }

    double inertia = 1.0;
    for (usz iteration = 0; iteration < ITERATION_COUNT; iteration++) {
        for (usz particle = 0; particle < PARTICLE_COUNT; particle++) {
            double[DIMENSION_COUNT] personal_random;
            double[DIMENSION_COUNT] social_random;
            for (usz coordinate = 0; coordinate < DIMENSION_COUNT; coordinate++)
                personal_random[coordinate] = next_uniform(&random_state);
            for (usz coordinate = 0; coordinate < DIMENSION_COUNT; coordinate++)
                social_random[coordinate] = next_uniform(&random_state);

            for (usz coordinate = 0; coordinate < DIMENSION_COUNT; coordinate++) {
                double cognitive = (2.0 * personal_random[coordinate]) *
                    (personal_position[particle][coordinate] - position[particle][coordinate]);
                double social = (2.0 * social_random[coordinate]) *
                    (global_position[coordinate] - position[particle][coordinate]);
                velocity[particle][coordinate] = inertia * velocity[particle][coordinate] + cognitive + social;
                position[particle][coordinate] += velocity[particle][coordinate];
            }

            double cost = sphere(&position[particle][0]);
            if (cost < personal_cost[particle]) {
                personal_cost[particle] = cost;
                for (usz coordinate = 0; coordinate < DIMENSION_COUNT; coordinate++) {
                    personal_position[particle][coordinate] = position[particle][coordinate];
                }
                if (personal_cost[particle] < global_cost) {
                    global_cost = personal_cost[particle];
                    for (usz coordinate = 0; coordinate < DIMENSION_COUNT; coordinate++)
                        global_position[coordinate] = personal_position[particle][coordinate];
                }
            }
        }
        history[iteration] = global_cost;
        inertia *= 0.99;
    }

    usz offset = 0;
    write_f64_le(global_cost, output, offset);
    offset += 8;
    for (usz coordinate = 0; coordinate < DIMENSION_COUNT; coordinate++) {
        write_f64_le(global_position[coordinate], output, offset);
        offset += 8;
    }
    for (usz iteration = 0; iteration < ITERATION_COUNT; iteration++) {
        write_f64_le(history[iteration], output, offset);
        offset += 8;
    }
    return (long)OUTPUT_BYTES;
}
