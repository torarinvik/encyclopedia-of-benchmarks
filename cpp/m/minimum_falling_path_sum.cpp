#include <cstddef>
#include <cstdint>

extern "C" std::int64_t minimum_falling_path_sum(const std::int64_t *input, std::size_t length)
{
    constexpr std::size_t max_n = 100;
    constexpr std::int64_t invalid_result = -10001;
    if (input == nullptr || length < 1 || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n))
        return invalid_result;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length != 1 + n * n) return invalid_result;
    for (std::size_t index = 0; index < n * n; ++index)
        if (input[1 + index] < -100 || input[1 + index] > 100) return invalid_result;

    std::int64_t costs[max_n];
    std::int64_t next_costs[max_n];
    for (std::size_t column = 0; column < n; ++column) costs[column] = input[1 + column];
    for (std::size_t row = 1; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            std::int64_t best = costs[column];
            if (column > 0 && costs[column - 1] < best) best = costs[column - 1];
            if (column + 1 < n && costs[column + 1] < best) best = costs[column + 1];
            next_costs[column] = best + input[1 + row * n + column];
        }
        for (std::size_t column = 0; column < n; ++column) costs[column] = next_costs[column];
    }
    std::int64_t minimum = costs[0];
    for (std::size_t column = 1; column < n; ++column)
        if (costs[column] < minimum) minimum = costs[column];
    return minimum;
}
