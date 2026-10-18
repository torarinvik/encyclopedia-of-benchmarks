#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_cities = 8;
constexpr std::size_t max_input_length = 66;
constexpr std::int64_t java_int_min = INT64_C(-2147483648);
constexpr std::int64_t java_int_max = INT64_C(2147483647);
constexpr std::int64_t max_edge_cost = 1000;

void evaluate_permutation(const std::int64_t *matrix, std::size_t city_count,
                          const std::size_t *order, std::int64_t &best) noexcept
{
    std::int64_t cost = 0;
    std::size_t previous = 0;
    for (std::size_t index = 0; index < city_count - 1; ++index) {
        const auto city = order[index];
        const auto edge = matrix[previous * city_count + city];
        if (edge == java_int_max) return;
        cost += edge;
        previous = city;
    }
    const auto return_edge = matrix[previous * city_count];
    if (return_edge == java_int_max) return;
    cost += return_edge;
    if (cost < best) best = cost;
}

void enumerate_permutations(const std::int64_t *matrix, std::size_t city_count,
                            std::size_t *order, std::size_t position,
                            std::int64_t &best) noexcept
{
    if (position == city_count - 1) {
        evaluate_permutation(matrix, city_count, order, best);
        return;
    }
    for (std::size_t index = position; index < city_count - 1; ++index) {
        const auto temporary = order[position];
        order[position] = order[index];
        order[index] = temporary;
        enumerate_permutations(matrix, city_count, order, position + 1, best);
        order[index] = order[position];
        order[position] = temporary;
    }
}
}

extern "C" std::int64_t traveling_salesman(const std::int64_t *input,
                                             std::size_t length) noexcept
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto city_count_value = input[0];
    if (city_count_value < 0 || city_count_value > static_cast<std::int64_t>(max_cities)) return -1;
    const auto city_count = static_cast<std::size_t>(city_count_value);
    if (length != 1 + city_count * city_count) return -1;

    for (std::size_t index = 0; index < city_count * city_count; ++index) {
        const auto value = input[1 + index];
        if (value < java_int_min || value > java_int_max) return -1;
    }
    if (city_count <= 1) return 0;

    for (std::size_t row = 0; row < city_count; ++row) {
        for (std::size_t column = 0; column < city_count; ++column) {
            if (row == column) continue;
            const auto edge = input[1 + row * city_count + column];
            if (edge != java_int_max && (edge < 0 || edge > max_edge_cost)) return -1;
        }
    }

    std::size_t order[max_cities - 1];
    for (std::size_t city = 1; city < city_count; ++city) order[city - 1] = city;
    auto best = java_int_max;
    enumerate_permutations(input + 1, city_count, order, 0, best);
    return best;
}
