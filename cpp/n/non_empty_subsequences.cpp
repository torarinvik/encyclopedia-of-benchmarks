#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_runes = 8;
constexpr std::size_t max_input_length = max_runes + 2;
constexpr std::size_t bytes_per_value = 4;

bool is_unicode_scalar(std::int64_t value) noexcept {
    return value >= 0 && value <= 0x10ffff && !(value >= 0xd800 && value <= 0xdfff);
}

void store_u32_le(std::uint8_t *output, std::size_t position, std::uint32_t value) noexcept {
    for (std::size_t byte = 0; byte < bytes_per_value; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(value >> (byte * 8));
}

void emit_row(const std::int32_t *current, std::size_t length, std::uint8_t *output,
              std::size_t &output_cursor, std::size_t &row_count) {
    store_u32_le(output, output_cursor, static_cast<std::uint32_t>(length));
    output_cursor += bytes_per_value;
    for (std::size_t item = 0; item < length; ++item) {
        store_u32_le(output, output_cursor, static_cast<std::uint32_t>(current[item]));
        output_cursor += bytes_per_value;
    }
    ++row_count;
}

void generate(const std::int32_t *values, std::size_t n, std::size_t start,
              std::int32_t *current, std::size_t current_length, std::uint8_t *output,
              std::size_t &output_cursor, std::size_t &row_count) {
    for (std::size_t index = start; index < n; ++index) {
        current[current_length] = values[index];
        emit_row(current, current_length + 1, output, output_cursor, row_count);
        generate(values, n, index + 1, current, current_length + 1,
                 output, output_cursor, row_count);
    }
}
}

extern "C" std::int64_t non_empty_subsequences(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto count_value = input[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_runes) ||
        length != static_cast<std::size_t>(count_value) + 1) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    std::int32_t values[max_runes];
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[index + 1];
        if (!is_unicode_scalar(value)) return -1;
        values[index] = static_cast<std::int32_t>(value);
    }

    const auto row_count = (static_cast<std::size_t>(1) << count) - 1;
    const auto value_count = count * (static_cast<std::size_t>(1) << (count - 1));
    const auto required = (row_count + value_count) * bytes_per_value;
    if (output_capacity < required || output == nullptr) return -2;

    std::int32_t current[max_runes];
    std::size_t output_cursor = 0;
    std::size_t emitted = 0;
    generate(values, count, 0, current, 0, output, output_cursor, emitted);
    return static_cast<std::int64_t>(emitted);
}
