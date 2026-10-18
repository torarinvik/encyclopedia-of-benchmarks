#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr std::size_t min_cities = 2;
constexpr std::size_t max_cities = 8;
constexpr std::size_t max_input_length = 67;
constexpr std::int64_t max_edge_cost = 1000;

void evaluate_route(const std::int64_t *matrix, std::size_t city_count,
                    const std::size_t *order, std::int64_t &best_distance,
                    std::size_t *best_route) noexcept
{
    std::size_t route[max_cities + 1]{};
    route[0] = 0;
    for (std::size_t index = 0; index < city_count - 1; ++index)
        route[index + 1] = order[index];
    route[city_count] = 0;

    std::int64_t distance = 0;
    for (std::size_t index = 0; index < city_count; ++index)
        distance += matrix[route[index] * city_count + route[index + 1]];
    if (distance < best_distance) {
        best_distance = distance;
        for (std::size_t index = 0; index <= city_count; ++index)
            best_route[index] = route[index];
    }
}

void enumerate_routes(const std::int64_t *matrix, std::size_t city_count,
                      std::size_t *order, std::size_t position, bool *used,
                      std::int64_t &best_distance, std::size_t *best_route) noexcept
{
    if (position == city_count - 1) {
        evaluate_route(matrix, city_count, order, best_distance, best_route);
        return;
    }
    for (std::size_t city = 1; city < city_count; ++city) {
        if (used[city]) continue;
        used[city] = true;
        order[position] = city;
        enumerate_routes(matrix, city_count, order, position + 1, used,
                         best_distance, best_route);
        used[city] = false;
    }
}
}

extern "C" double traveling_salesman_solver_brute_force(const std::int64_t *input,
                                                          std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > max_input_length) return invalid_result;
    const auto selector = input[0];
    const auto city_count_value = input[1];
    if (city_count_value < static_cast<std::int64_t>(min_cities) ||
        city_count_value > static_cast<std::int64_t>(max_cities)) return invalid_result;
    const auto city_count = static_cast<std::size_t>(city_count_value);
    if (selector < 0 || selector > static_cast<std::int64_t>(city_count) + 1 ||
        length != 2 + city_count * city_count) return invalid_result;

    const auto *matrix = input + 2;
    for (std::size_t index = 0; index < city_count * city_count; ++index)
        if (matrix[index] < 0 || matrix[index] > max_edge_cost) return invalid_result;

    std::size_t order[max_cities - 1]{};
    bool used[max_cities]{};
    used[0] = true;
    std::int64_t best_distance = 8001;
    std::size_t best_route[max_cities + 1]{};
    enumerate_routes(matrix, city_count, order, 0, used, best_distance, best_route);
    if (selector == 0) return static_cast<double>(best_distance);
    return static_cast<double>(best_route[static_cast<std::size_t>(selector - 1)]);
}
