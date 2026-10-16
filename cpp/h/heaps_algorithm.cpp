#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 6;
constexpr std::size_t bytes_per_value = 8;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < bytes_per_value; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void emit_row(const std::int64_t *values, std::size_t n, std::uint8_t *output,
              std::size_t &rows) noexcept {
    const std::size_t row_offset = rows * n * bytes_per_value;
    for (std::size_t index = 0; index < n; ++index)
        store_i64_le(output, row_offset + index * bytes_per_value, values[index]);
    ++rows;
}

void generate(std::int64_t *values, std::size_t n, std::size_t k,
              std::uint8_t *output, std::size_t &rows) noexcept {
    if (k == 1) {
        emit_row(values, n, output, rows);
        return;
    }
    generate(values, n, k - 1, output, rows);
    for (std::size_t index = 0; index < k - 1; ++index) {
        const std::size_t swap_index = k % 2 == 0 ? index : 0;
        const auto temporary = values[swap_index];
        values[swap_index] = values[k - 1];
        values[k - 1] = temporary;
        generate(values, n, k - 1, output, rows);
    }
}
}

extern "C" std::int64_t heaps_algorithm(const std::int64_t *values, std::size_t length,
                                        std::uint8_t *output, std::size_t capacity) noexcept {
    if (values == nullptr || length < 1 || length > max_values) return -1;
    std::size_t row_count = 1;
    for (std::size_t factor = 2; factor <= length; ++factor) row_count *= factor;
    const std::size_t required = row_count * length * bytes_per_value;
    if (output == nullptr || capacity < required) return -2;
    std::int64_t items[max_values];
    for (std::size_t index = 0; index < length; ++index) items[index] = values[index];
    std::size_t rows = 0;
    generate(items, length, length, output, rows);
    return static_cast<std::int64_t>(rows);
}
