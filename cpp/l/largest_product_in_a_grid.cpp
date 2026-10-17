/* Largest product of four adjacent values in a bounded grid. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t largest_product_in_a_grid(const std::int64_t *values,
                                                   std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 3971) return -1;

    const std::int64_t rows = values[0];
    const std::int64_t cols = values[1];
    if (rows < 0 || rows > 63 || cols < 0 || cols > 63) return -1;

    const std::size_t expected_length = 2 + static_cast<std::size_t>(rows) * static_cast<std::size_t>(cols);
    if (length != expected_length) return -1;
    for (std::size_t index = 2; index < length; ++index) {
        if (values[index] < 0 || values[index] > 1000) return -1;
    }

    constexpr std::int64_t row_steps[4] = {0, 1, 1, 1};
    constexpr std::int64_t col_steps[4] = {1, 0, 1, -1};
    std::int64_t best = 0;
    for (std::size_t row = 0; row < static_cast<std::size_t>(rows); ++row) {
        for (std::size_t col = 0; col < static_cast<std::size_t>(cols); ++col) {
            for (std::size_t direction = 0; direction < 4; ++direction) {
                std::int64_t product = 1;
                for (std::int64_t offset = 0; offset < 4; ++offset) {
                    const std::int64_t next_row = static_cast<std::int64_t>(row) + offset * row_steps[direction];
                    const std::int64_t next_col = static_cast<std::int64_t>(col) + offset * col_steps[direction];
                    if (next_row < 0 || next_row >= rows || next_col < 0 || next_col >= cols) {
                        product = 0;
                        break;
                    }
                    const std::size_t index = 2 + static_cast<std::size_t>(next_row) * static_cast<std::size_t>(cols)
                        + static_cast<std::size_t>(next_col);
                    product *= values[index];
                }
                if (product > best) best = product;
            }
        }
    }
    return best;
}
