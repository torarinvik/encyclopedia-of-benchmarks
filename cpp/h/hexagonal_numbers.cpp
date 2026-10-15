// Emit the zero-based hexagonal number sequence as little-endian i64 values.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_length = 1024;
constexpr std::size_t bytes_per_value = 8;

void store_i64_le(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < bytes_per_value; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t hexagonal_numbers(std::int64_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (length < 1 || length > max_length) return -1;
    const auto n = static_cast<std::size_t>(length);
    const auto required = n * bytes_per_value;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t index = 0; index < n; ++index) {
        const auto i = static_cast<std::int64_t>(index);
        store_i64_le(output, index * bytes_per_value, i * (2 * i - 1));
    }
    return length;
}
