#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_cities = 10;
constexpr std::size_t max_masks = 1024;
constexpr std::size_t max_input_values = 102;
constexpr std::int64_t max_distance = 1000;

std::int64_t solve(std::size_t position, std::size_t mask, std::size_t city_count,
                   const std::int64_t *distances,
                   std::int64_t memo[max_cities][max_masks],
                   bool seen[max_cities][max_masks]) noexcept {
    const auto all_visited = (std::size_t{1} << city_count) - 1;
    if (mask == all_visited) return distances[position * city_count];
    if (seen[position][mask]) return memo[position][mask];

    auto best = INT64_MAX;
    seen[position][mask] = true;
    for (std::size_t city = 0; city < city_count; ++city) {
        const auto bit = std::size_t{1} << city;
        if ((mask & bit) == 0) {
            const auto cost = distances[position * city_count + city] +
                solve(city, mask | bit, city_count, distances, memo, seen);
            if (cost < best) best = cost;
        }
    }
    memo[position][mask] = best;
    return best;
}
}

extern "C" std::int64_t traveling_salesman_bitmask(const std::int64_t *input,
                                                     std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_input_values) return -1;
    const auto city_count_value = input[0];
    if (city_count_value < 2 || city_count_value > static_cast<std::int64_t>(max_cities)) return -1;
    const auto city_count = static_cast<std::size_t>(city_count_value);
    if (length != 1 + city_count * city_count) return -1;

    std::int64_t distances[max_cities * max_cities];
    for (std::size_t index = 0; index < city_count * city_count; ++index) {
        const auto distance = input[1 + index];
        if (distance < 0 || distance > max_distance) return -1;
        if (index / city_count == index % city_count && distance != 0) return -1;
        distances[index] = distance;
    }

    std::int64_t memo[max_cities][max_masks]{};
    bool seen[max_cities][max_masks]{};
    return solve(0, 1, city_count, distances, memo, seen);
}
