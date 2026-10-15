#include <cstddef>
#include <cstdint>

extern "C" std::int64_t count_negative_numbers_in_sorted_matrix(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 3 || length > 514) return -1;
    const std::int64_t rows_value = input[0];
    const std::int64_t columns_value = input[1];
    if (rows_value < 1 || rows_value > 512 || columns_value < 1 || columns_value > 512) return -1;
    const std::size_t rows = static_cast<std::size_t>(rows_value);
    const std::size_t columns = static_cast<std::size_t>(columns_value);
    if (rows * columns > 512 || length != 2 + rows * columns) return -1;

    std::size_t nonnegative = 0;
    std::size_t bound = columns;
    for (std::size_t row = 0; row < rows; ++row) {
        std::size_t left = 0;
        std::size_t right = bound;
        while (left < right) {
            const std::size_t middle = left + (right - left) / 2;
            const std::int64_t value = input[2 + row * columns + middle];
            if (value >= 0) left = middle + 1;
            else right = middle;
        }
        bound = left;
        nonnegative += bound;
    }
    return static_cast<std::int64_t>(rows * columns - nonnegative);
}
