/* ASCII case-insensitive Burrows-Wheeler transform over packed bytes. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxLength = 256;
std::uint8_t fold_ascii(std::int64_t value) noexcept {
    const auto byte = static_cast<std::uint8_t>(value);
    return byte >= 'A' && byte <= 'Z' ? static_cast<std::uint8_t>(byte + ('a' - 'A')) : byte;
}
bool rotation_less(const std::int64_t *values, std::size_t n,
                   std::size_t left, std::size_t right) noexcept {
    for (std::size_t offset = 0; offset < n; ++offset) {
        const auto a = fold_ascii(values[1 + (left + offset) % n]);
        const auto b = fold_ascii(values[1 + (right + offset) % n]);
        if (a != b) return a < b;
    }
    return left < right;
}
bool rotation_equals_input(const std::int64_t *values, std::size_t n, std::size_t start) noexcept {
    for (std::size_t offset = 0; offset < n; ++offset)
        if (values[1 + (start + offset) % n] != values[1 + offset]) return false;
    return true;
}
}

extern "C" std::int64_t burrows_wheeler_transform_case_insensitive(const std::int64_t *values,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 1 || values[0] < 0 || values[0] > MaxLength) return -1;
    const auto n = static_cast<std::size_t>(values[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 1; i < length; ++i) if (values[i] < 0 || values[i] > 127) return -1;
    const auto output_length = n + 4;
    if (output_capacity < output_length || output == nullptr) return -2;

    std::size_t order[MaxLength];
    for (std::size_t i = 0; i < n; ++i) order[i] = i;
    for (std::size_t i = 1; i < n; ++i) {
        const auto key = order[i];
        auto position = i;
        while (position > 0 && rotation_less(values, n, key, order[position - 1])) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = key;
    }

    std::size_t primary_index = 0;
    for (std::size_t row = 0; row < n; ++row)
        if (rotation_equals_input(values, n, order[row])) primary_index = row;
    const auto encoded_index = static_cast<std::uint32_t>(primary_index);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[byte] = static_cast<std::uint8_t>(encoded_index >> (8 * byte));
    for (std::size_t row = 0; row < n; ++row)
        output[4 + row] = static_cast<std::uint8_t>(values[1 + (order[row] + n - 1) % n]);
    return static_cast<std::int64_t>(output_length);
}
