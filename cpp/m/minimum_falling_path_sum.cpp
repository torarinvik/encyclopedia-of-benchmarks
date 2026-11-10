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

    std::uint16_t costs[max_n + 2];
    std::uint16_t next_costs[max_n];
    costs[0] = 32768;
    costs[n + 1] = 32768;
    for (std::size_t column = 0; column < n; ++column)
        costs[column + 1] = static_cast<std::uint16_t>(input[1 + column] + 100);
    for (std::size_t row = 1; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            const std::uint16_t left = costs[column];
            const std::uint16_t center = costs[column + 1];
            const std::uint16_t right = costs[column + 2];
            const std::uint16_t left_or_center = left < center ? left : center;
            const std::uint16_t best = right < left_or_center ? right : left_or_center;
            next_costs[column] = best + static_cast<std::uint16_t>(input[1 + row * n + column] + 100);
        }
        for (std::size_t column = 0; column < n; ++column)
            costs[column + 1] = next_costs[column];
    }
    std::uint16_t minimum = costs[1];
    for (std::size_t column = 1; column < n; ++column)
        if (costs[column + 1] < minimum) minimum = costs[column + 1];
    return static_cast<std::int64_t>(minimum) - 100 * static_cast<std::int64_t>(n);
}
