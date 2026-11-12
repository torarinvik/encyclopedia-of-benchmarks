#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 10;
constexpr std::size_t max_input_values = 3;
constexpr std::size_t output_bytes = 8;

std::size_t cycle_count(std::size_t n, std::size_t shift, bool reflection) noexcept {
    bool seen[max_n]{};
    std::size_t cycles = 0;
    for (std::size_t start = 0; start < n; ++start) {
        if (seen[start]) continue;
        ++cycles;
        auto position = start;
        while (!seen[position]) {
            seen[position] = true;
            position = reflection ? (shift + n - position) % n
                                  : (position + shift) % n;
        }
    }
    return cycles;
}

std::int64_t fixed_colorings(std::size_t n, std::size_t shift,
                             bool reflection, std::int64_t colors) noexcept {
    const auto cycles = cycle_count(n, shift, reflection);
    std::int64_t result = 1;
    for (std::size_t cycle = 0; cycle < cycles; ++cycle) result *= colors;
    return result;
}

void store_i64_le(std::uint8_t *output, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < output_bytes; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t burnside_bracelets(const std::int64_t *input,
                                            std::size_t length,
                                            std::uint8_t *output,
                                            std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_values) return -1;
    if (length != 2) return -1;
    const auto n_value = input[0];
    const auto colors = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)
        || colors < 0 || colors > 3) return -1;
    const auto n = static_cast<std::size_t>(n_value);

    std::int64_t fixed_sum = 0;
    for (std::size_t shift = 0; shift < n; ++shift) {
        fixed_sum += fixed_colorings(n, shift, false, colors);
        fixed_sum += fixed_colorings(n, shift, true, colors);
    }
    const auto answer = fixed_sum / static_cast<std::int64_t>(2 * n);
    if (output == nullptr || capacity < output_bytes) return -2;
    store_i64_le(output, answer);
    return static_cast<std::int64_t>(output_bytes);
}
