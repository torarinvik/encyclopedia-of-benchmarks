/* Return whether strictly more than half of a matrix's entries are zero. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t sparse_matrix(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 4099) return -1;
    const std::int64_t rows_value = values[0], columns_value = values[1];
    if (rows_value < 1 || rows_value > 64 || columns_value < 1 || columns_value > 64) return -1;
    const std::size_t rows = static_cast<std::size_t>(rows_value);
    const std::size_t columns = static_cast<std::size_t>(columns_value);
    const std::size_t cells = rows * columns;
    if (length != 2 + cells) return -1;
    std::int64_t zero_count = 0;
    for (std::size_t index = 0; index < cells; ++index) {
        const std::int64_t value = values[2 + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (value == 0) ++zero_count;
    }
    return zero_count > static_cast<std::int64_t>(cells / 2) ? 1 : 0;
}
