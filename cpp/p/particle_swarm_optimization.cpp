#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t particle_count = 50;
constexpr std::size_t dimension_count = 5;
constexpr std::size_t iteration_count = 1000;
constexpr std::size_t max_input_length = 2;
constexpr std::size_t output_value_count = 1 + dimension_count + iteration_count;
constexpr std::size_t output_bytes = output_value_count * 8;

double next_uniform(std::uint64_t& state) noexcept {
    state ^= state << 13;
    state ^= state >> 7;
    state ^= state << 17;
    return static_cast<double>(state >> 11) * 0x1.0p-53;
}

double sphere(const double point[dimension_count]) noexcept {
    double cost = 0.0;
    for (std::size_t coordinate = 0; coordinate < dimension_count; ++coordinate)
        cost += point[coordinate] * point[coordinate];
    return cost;
}

void write_f64_le(std::uint8_t* output, std::size_t offset, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t particle_swarm_optimization(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length || length != 1 || input[0] <= 0)
        return -1;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    std::uint64_t random_state = static_cast<std::uint64_t>(input[0]);
    double position[particle_count][dimension_count]{};
    double velocity[particle_count][dimension_count]{};
    double personal_position[particle_count][dimension_count]{};
    double personal_cost[particle_count]{};
    double global_position[dimension_count]{};
    double history[iteration_count]{};
    double global_cost = 1.7976931348623157e308;

    for (std::size_t particle = 0; particle < particle_count; ++particle) {
        for (std::size_t coordinate = 0; coordinate < dimension_count; ++coordinate) {
            position[particle][coordinate] = -10.0 + 20.0 * next_uniform(random_state);
            personal_position[particle][coordinate] = position[particle][coordinate];
        }
        personal_cost[particle] = sphere(position[particle]);
        if (personal_cost[particle] < global_cost) {
            global_cost = personal_cost[particle];
            std::memcpy(global_position, personal_position[particle], sizeof(global_position));
        }
    }

    double inertia = 1.0;
    for (std::size_t iteration = 0; iteration < iteration_count; ++iteration) {
        for (std::size_t particle = 0; particle < particle_count; ++particle) {
            double personal_random[dimension_count];
            double social_random[dimension_count];
            for (std::size_t coordinate = 0; coordinate < dimension_count; ++coordinate)
                personal_random[coordinate] = next_uniform(random_state);
            for (std::size_t coordinate = 0; coordinate < dimension_count; ++coordinate)
                social_random[coordinate] = next_uniform(random_state);

            for (std::size_t coordinate = 0; coordinate < dimension_count; ++coordinate) {
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
                std::memcpy(personal_position[particle], position[particle], sizeof(position[particle]));
                if (personal_cost[particle] < global_cost) {
                    global_cost = personal_cost[particle];
                    std::memcpy(global_position, personal_position[particle], sizeof(global_position));
                }
            }
        }
        history[iteration] = global_cost;
        inertia *= 0.99;
    }

    std::size_t offset = 0;
    write_f64_le(output, offset, global_cost);
    offset += 8;
    for (std::size_t coordinate = 0; coordinate < dimension_count; ++coordinate) {
        write_f64_le(output, offset, global_position[coordinate]);
        offset += 8;
    }
    for (std::size_t iteration = 0; iteration < iteration_count; ++iteration) {
        write_f64_le(output, offset, history[iteration]);
        offset += 8;
    }
    return static_cast<std::int64_t>(output_bytes);
}
