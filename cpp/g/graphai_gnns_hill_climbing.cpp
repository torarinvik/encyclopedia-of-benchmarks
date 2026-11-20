#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 16;
constexpr std::size_t max_d = 4;
constexpr std::size_t max_input = 89;
constexpr std::size_t max_parseable = 90;
constexpr std::int64_t coordinate_limit = 100;
constexpr std::int64_t distance_radix = 160001;
}

extern "C" std::int64_t graphai_gnns_hill_climbing(const std::int64_t* input,
                                                    std::size_t length) noexcept {
    if (input == nullptr || length < 5 || length > max_parseable) return -1;
    const auto n_value = input[0], d_value = input[1], start_value = input[2];
    const auto e_value = input[3], t_value = input[4];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_n) ||
        d_value < 1 || d_value > static_cast<std::int64_t>(max_d) ||
        start_value < 0 || start_value >= n_value || e_value < 1 || e_value >= n_value ||
        t_value < 0 || t_value > 16) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto d = static_cast<std::size_t>(d_value);
    if (length != 5 + n * d + n + d || length > max_input) return -1;

    std::array<std::int64_t, max_n * max_d> coordinates{};
    for (std::size_t i = 0; i < n * d; ++i) {
        coordinates[i] = input[5 + i];
        if (coordinates[i] < -coordinate_limit || coordinates[i] > coordinate_limit) return -1;
    }
    const std::size_t mask_offset = 5 + n * d;
    std::array<std::int64_t, max_n> masks{};
    const std::int64_t allowed = (std::int64_t{1} << n) - 1;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        const auto mask = input[mask_offset + vertex];
        if (mask < 0 || (mask & ~allowed) != 0 || (mask & (std::int64_t{1} << vertex)) != 0) return -1;
        masks[vertex] = mask;
    }
    std::array<std::int64_t, max_d> query{};
    for (std::size_t axis = 0; axis < d; ++axis) {
        query[axis] = input[mask_offset + n + axis];
        if (query[axis] < -coordinate_limit || query[axis] > coordinate_limit) return -1;
    }

    auto current = static_cast<std::size_t>(start_value);
    std::int64_t current_distance = 0;
    for (std::size_t axis = 0; axis < d; ++axis) {
        const auto delta = coordinates[current * d + axis] - query[axis];
        current_distance += delta * delta;
    }
    std::int64_t evaluations = 1, moves = 0;
    for (std::int64_t step = 0; step < t_value; ++step) {
        auto best_vertex = current;
        auto best_distance = current_distance;
        std::int64_t inspected = 0;
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            if ((masks[current] & (std::int64_t{1} << vertex)) == 0) continue;
            std::int64_t distance = 0;
            for (std::size_t axis = 0; axis < d; ++axis) {
                const auto delta = coordinates[vertex * d + axis] - query[axis];
                distance += delta * delta;
            }
            ++evaluations;
            ++inspected;
            if (distance < best_distance || (distance == best_distance && vertex < best_vertex)) {
                best_vertex = vertex;
                best_distance = distance;
            }
            if (inspected == e_value) break;
        }
        if (best_distance >= current_distance) break;
        current = best_vertex;
        current_distance = best_distance;
        ++moves;
    }
    return (((evaluations * 17 + moves) * 16 + static_cast<std::int64_t>(current)) * distance_radix
            + current_distance);
}
