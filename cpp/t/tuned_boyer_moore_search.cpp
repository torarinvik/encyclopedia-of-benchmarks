// Bounded all-occurrences Tuned Boyer–Moore search.
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 255;
constexpr std::size_t max_pattern = 64;
constexpr std::size_t max_frame = 322;
constexpr std::size_t alphabet_size = 128;
constexpr std::size_t max_padded = max_text + max_pattern;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tuned_boyer_moore_search(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 2 || length > max_frame) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_pattern)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + m) return -1;
    for (std::size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 127) return -1;

    std::int64_t positions[max_text]{};
    std::size_t match_count = 0;
    if (m <= n) {
        std::uint8_t padded[max_padded]{};
        std::size_t shifts[alphabet_size];
        const auto pattern_start = 2 + n;
        const auto final_byte = static_cast<std::uint8_t>(input[pattern_start + m - 1]);
        for (std::size_t i = 0; i < n; ++i) padded[i] = static_cast<std::uint8_t>(input[2 + i]);
        std::fill_n(padded + n, m, final_byte);
        std::fill_n(shifts, alphabet_size, m);
        for (std::size_t i = 0; i + 1 < m; ++i)
            shifts[static_cast<std::size_t>(input[pattern_start + i])] = m - i - 1;
        const auto final_shift = shifts[final_byte];
        shifts[final_byte] = 0;
        for (std::size_t alignment = 0; alignment < n;) {
            auto skip = shifts[padded[alignment + m - 1]];
            while (skip != 0) {
                alignment += skip; skip = shifts[padded[alignment + m - 1]];
                alignment += skip; skip = shifts[padded[alignment + m - 1]];
                alignment += skip; skip = shifts[padded[alignment + m - 1]];
            }
            bool prefix_matches = true;
            for (std::size_t i = 0; i + 1 < m; ++i) {
                if (static_cast<std::uint8_t>(input[pattern_start + i]) != padded[alignment + i]) {
                    prefix_matches = false;
                    break;
                }
            }
            if (prefix_matches && alignment < n) positions[match_count++] = static_cast<std::int64_t>(alignment);
            alignment += final_shift;
        }
    }
    const auto output_bytes = match_count * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < match_count; ++i) store_i64_le(output, i * 8, positions[i]);
    return static_cast<std::int64_t>(output_bytes);
}
