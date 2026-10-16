#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define PARTICLE_COUNT 50
#define DIMENSION_COUNT 5
#define ITERATION_COUNT 1000
#define MAX_INPUT_LENGTH 2
#define OUTPUT_VALUE_COUNT (1 + DIMENSION_COUNT + ITERATION_COUNT)
#define OUTPUT_BYTES (OUTPUT_VALUE_COUNT * 8)

static double next_uniform(uint64_t *state)
{
    uint64_t value = *state;
    value ^= value << 13;
    value ^= value >> 7;
    value ^= value << 17;
    *state = value;
    return (double)(value >> 11) * 0x1.0p-53;
}

static double sphere(const double point[DIMENSION_COUNT])
{
    double cost = 0.0;
    for (size_t coordinate = 0; coordinate < DIMENSION_COUNT; ++coordinate)
        cost += point[coordinate] * point[coordinate];
    return cost;
}

static void write_f64_le(uint8_t *output, size_t offset, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t particle_swarm_optimization(const int64_t *input, size_t length,
                                    uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH ||
        length != 1 || input[0] <= 0) return -1;
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;

    uint64_t random_state = (uint64_t)input[0];
    double position[PARTICLE_COUNT][DIMENSION_COUNT];
    double velocity[PARTICLE_COUNT][DIMENSION_COUNT] = {{0.0}};
    double personal_position[PARTICLE_COUNT][DIMENSION_COUNT];
    double personal_cost[PARTICLE_COUNT];
    double global_position[DIMENSION_COUNT] = {0.0};
    double history[ITERATION_COUNT];
    double global_cost = 1.7976931348623157e308;

    for (size_t particle = 0; particle < PARTICLE_COUNT; ++particle) {
        for (size_t coordinate = 0; coordinate < DIMENSION_COUNT; ++coordinate) {
            position[particle][coordinate] = -10.0 + 20.0 * next_uniform(&random_state);
            personal_position[particle][coordinate] = position[particle][coordinate];
        }
        personal_cost[particle] = sphere(position[particle]);
        if (personal_cost[particle] < global_cost) {
            global_cost = personal_cost[particle];
            memcpy(global_position, personal_position[particle], sizeof(global_position));
        }
    }

    double inertia = 1.0;
    for (size_t iteration = 0; iteration < ITERATION_COUNT; ++iteration) {
        for (size_t particle = 0; particle < PARTICLE_COUNT; ++particle) {
            double personal_random[DIMENSION_COUNT];
            double social_random[DIMENSION_COUNT];
            for (size_t coordinate = 0; coordinate < DIMENSION_COUNT; ++coordinate)
                personal_random[coordinate] = next_uniform(&random_state);
            for (size_t coordinate = 0; coordinate < DIMENSION_COUNT; ++coordinate)
                social_random[coordinate] = next_uniform(&random_state);

            for (size_t coordinate = 0; coordinate < DIMENSION_COUNT; ++coordinate) {
                const double cognitive = (2.0 * personal_random[coordinate]) *
                    (personal_position[particle][coordinate] - position[particle][coordinate]);
                const double social = (2.0 * social_random[coordinate]) *
                    (global_position[coordinate] - position[particle][coordinate]);
                velocity[particle][coordinate] = inertia * velocity[particle][coordinate] + cognitive + social;
                position[particle][coordinate] += velocity[particle][coordinate];
            }

            const double cost = sphere(position[particle]);
            if (cost < personal_cost[particle]) {
                personal_cost[particle] = cost;
                memcpy(personal_position[particle], position[particle], sizeof(position[particle]));
                if (personal_cost[particle] < global_cost) {
                    global_cost = personal_cost[particle];
                    memcpy(global_position, personal_position[particle], sizeof(global_position));
                }
            }
        }
        history[iteration] = global_cost;
        inertia *= 0.99;
    }

    size_t offset = 0;
    write_f64_le(output, offset, global_cost);
    offset += 8;
    for (size_t coordinate = 0; coordinate < DIMENSION_COUNT; ++coordinate) {
        write_f64_le(output, offset, global_position[coordinate]);
        offset += 8;
    }
    for (size_t iteration = 0; iteration < ITERATION_COUNT; ++iteration) {
        write_f64_le(output, offset, history[iteration]);
        offset += 8;
    }
    return OUTPUT_BYTES;
}
