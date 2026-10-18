#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr std::size_t min_cities = 1;
constexpr std::size_t max_cities = 8;
constexpr std::size_t max_input_length = 68;
constexpr std::int64_t max_edge_cost = 1000;
}

extern "C" double traveling_salesman_solver_nearest_neighbor(const std::int64_t *input,
                                                               std::size_t length) noexcept
{
    if (input == nullptr || length < 4 || length > max_input_length) return invalid_result;
    const auto selector = input[0];
    const auto city_count_value = input[1];
    const auto start_value = input[2];
    if (city_count_value < static_cast<std::int64_t>(min_cities) ||
        city_count_value > static_cast<std::int64_t>(max_cities)) return invalid_result;
    const auto city_count = static_cast<std::size_t>(city_count_value);
    if (selector < 0 || selector > static_cast<std::int64_t>(city_count) + 1 ||
        start_value < 0 || start_value >= city_count_value ||
        length != 3 + city_count * city_count) return invalid_result;

    const auto *matrix = input + 3;
    for (std::size_t index = 0; index < city_count * city_count; ++index)
        if (matrix[index] < 0 || matrix[index] > max_edge_cost) return invalid_result;

    std::size_t route[max_cities + 1]{};
    bool visited[max_cities]{};
    const auto start = static_cast<std::size_t>(start_value);
    auto current = start;
    route[0] = start;
    visited[start] = true;
    std::int64_t total_distance = 0;

    for (std::size_t step = 1; step < city_count; ++step) {
        std::int64_t minimum_distance = 1001;
        std::size_t next_city = max_cities;
        for (std::size_t city = 0; city < city_count; ++city) {
            if (!visited[city]) {
                const auto distance = matrix[current * city_count + city];
                if (distance < minimum_distance) {
                    minimum_distance = distance;
                    next_city = city;
                }
            }
        }
        if (next_city == max_cities) return invalid_result;
        route[step] = next_city;
        visited[next_city] = true;
        total_distance += minimum_distance;
        current = next_city;
    }
    total_distance += matrix[current * city_count + start];
    route[city_count] = start;

    if (selector == 0) return static_cast<double>(total_distance);
    return static_cast<double>(route[static_cast<std::size_t>(selector - 1)]);
}
