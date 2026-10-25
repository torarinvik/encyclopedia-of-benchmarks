#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input_length = 1 + max_n;
constexpr std::int64_t max_value = 1'000'000;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tsvc_s315_maximum_with_index(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(max_n)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    if (length != 1 + n) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] < -max_value || input[i + 1] > max_value) return -1;
    if (output == nullptr || output_capacity < 16) return -2;

    std::int64_t maximum = input[1];
    std::size_t maximum_index = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t value = input[i + 1];
        if (value > maximum) {
            maximum = value;
            maximum_index = i;
        }
    }
    store_i64_le(output, 0, maximum);
    store_i64_le(output, 8, static_cast<std::int64_t>(maximum_index));
    return 2;
}
