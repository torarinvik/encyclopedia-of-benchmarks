#include <cstddef>
#include <cstdint>

extern "C" std::int64_t number_of_ways_of_cutting_a_pizza(
    const std::int64_t *input, std::size_t length) noexcept
{
    constexpr std::size_t max_input = 39;
    constexpr std::int64_t modulus = 1000000007;
    if (input == nullptr || length < 3 || length > max_input) return -1;
    const auto rows_value = input[0];
    const auto columns_value = input[1];
    const auto cuts_value = input[2];
    if (rows_value < 1 || rows_value > 6 || columns_value < 1 || columns_value > 6
        || cuts_value < 0 || cuts_value > 5
        || length != 3 + static_cast<std::size_t>(rows_value * columns_value)) return -1;
    const auto rows = static_cast<std::size_t>(rows_value);
    const auto columns = static_cast<std::size_t>(columns_value);
    const auto cuts = static_cast<std::size_t>(cuts_value);
    constexpr std::size_t stride = 7;

    std::int64_t suffix[49]{};
    for (std::size_t row = 0; row < rows; ++row) {
        for (std::size_t column = 0; column < columns; ++column) {
            const auto cell = input[3 + row * columns + column];
            if (cell != 0 && cell != 1) return -1;
        }
    }
    for (std::size_t row = rows; row-- > 0;) {
        for (std::size_t column = columns; column-- > 0;) {
            const auto cell = input[3 + row * columns + column];
            const auto at = row * stride + column;
            suffix[at] = cell + suffix[(row + 1) * stride + column]
                + suffix[row * stride + column + 1]
                - suffix[(row + 1) * stride + column + 1];
        }
    }

    std::int64_t previous[49]{};
    std::int64_t current[49]{};
    for (std::size_t row = 0; row < rows; ++row)
        for (std::size_t column = 0; column < columns; ++column)
            previous[row * stride + column] = suffix[row * stride + column] > 0 ? 1 : 0;

    for (std::size_t remaining = 1; remaining <= cuts; ++remaining) {
        for (std::size_t index = 0; index < 49; ++index) current[index] = 0;
        for (std::size_t row = rows; row-- > 0;) {
            for (std::size_t column = columns; column-- > 0;) {
                const auto origin = row * stride + column;
                std::int64_t ways = 0;
                for (std::size_t cut = row + 1; cut < rows; ++cut)
                    if (suffix[origin] - suffix[cut * stride + column] > 0)
                        ways += previous[cut * stride + column];
                for (std::size_t cut = column + 1; cut < columns; ++cut)
                    if (suffix[origin] - suffix[row * stride + cut] > 0)
                        ways += previous[row * stride + cut];
                current[origin] = ways % modulus;
            }
        }
        for (std::size_t index = 0; index < 49; ++index) previous[index] = current[index];
    }
    return previous[0];
}
