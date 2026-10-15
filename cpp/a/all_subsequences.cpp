// Emit subsequences in skip-before-include depth-first order.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_length = 8;
constexpr std::size_t bytes_per_value = 4;

void store_u32_le(std::uint8_t *output, std::size_t position, std::uint32_t value) noexcept {
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(value >> (byte * 8));
}

void store_i32_le(std::uint8_t *output, std::size_t position, std::int32_t value) noexcept {
    store_u32_le(output, position, static_cast<std::uint32_t>(value));
}

void generate(const std::int32_t *values, std::size_t n, std::size_t index,
              std::int32_t *current, std::size_t current_length,
              std::uint8_t *output, std::size_t &output_cursor,
              std::size_t &result_count) {
    if (index == n) {
        store_u32_le(output, output_cursor, static_cast<std::uint32_t>(current_length));
        output_cursor += bytes_per_value;
        for (std::size_t item = 0; item < current_length; ++item) {
            store_i32_le(output, output_cursor, current[item]);
            output_cursor += bytes_per_value;
        }
        ++result_count;
        return;
    }
    generate(values, n, index + 1, current, current_length, output, output_cursor, result_count);
    current[current_length] = values[index];
    generate(values, n, index + 1, current, current_length + 1,
             output, output_cursor, result_count);
}
}

extern "C" std::int64_t all_subsequences(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_length + 1) return -1;
    const auto n_value = input[0];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_length) ||
        length != static_cast<std::size_t>(n_value) + 1) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    std::int32_t values[max_length];
    for (std::size_t index = 0; index < n; ++index) {
        const auto value = input[index + 1];
        if (value < std::numeric_limits<std::int32_t>::min() || value > std::numeric_limits<std::int32_t>::max()) return -1;
        values[index] = static_cast<std::int32_t>(value);
    }
    std::size_t result_count = 1;
    for (std::size_t index = 0; index < n; ++index) result_count *= 2;
    const auto value_count = n == 0 ? 0 : n * (result_count / 2);
    const auto required = (result_count + value_count) * bytes_per_value;
    if (output_capacity < required || output == nullptr) return -2;
    std::int32_t current[max_length];
    std::size_t output_cursor = 0;
    std::size_t emitted = 0;
    generate(values, n, 0, current, 0, output, output_cursor, emitted);
    return static_cast<std::int64_t>(emitted);
}
