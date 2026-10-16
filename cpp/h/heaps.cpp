#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 7;

void emit_row(const std::uint8_t *items, std::size_t n, std::uint8_t *output,
              std::size_t &rows) noexcept {
    const std::size_t offset = rows * n;
    for (std::size_t index = 0; index < n; ++index) output[offset + index] = items[index];
    ++rows;
}

void generate(std::uint8_t *items, std::size_t n, std::size_t size,
              std::uint8_t *output, std::size_t &rows) noexcept {
    if (size == 1) {
        emit_row(items, n, output, rows);
        return;
    }
    for (std::size_t index = 0; index < size; ++index) {
        generate(items, n, size - 1, output, rows);
        const std::size_t swap_index = size % 2 == 1 ? index : 0;
        const auto temporary = items[swap_index];
        items[swap_index] = items[size - 1];
        items[size - 1] = temporary;
    }
}
}

extern "C" std::int64_t heaps(const std::int64_t *values, std::size_t length,
                               std::uint8_t *output, std::size_t capacity) noexcept {
    if (values == nullptr || length != 1 || values[0] < 0 || values[0] > max_n) return -1;
    const auto n = static_cast<std::size_t>(values[0]);
    if (n == 0) return 0;
    std::size_t row_count = 1;
    for (std::size_t factor = 2; factor <= n; ++factor) row_count *= factor;
    const std::size_t required = row_count * n;
    if (output == nullptr || capacity < required) return -2;
    std::uint8_t items[max_n];
    for (std::size_t index = 0; index < n; ++index)
        items[index] = static_cast<std::uint8_t>('1' + index);
    std::size_t rows = 0;
    generate(items, n, n, output, rows);
    return static_cast<std::int64_t>(rows);
}
