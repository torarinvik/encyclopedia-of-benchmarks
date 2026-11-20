// Bounded all-occurrences Raita search with Horspool shifts.
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 255;
constexpr std::size_t max_pattern = 64;
constexpr std::size_t max_frame = 322;
constexpr std::size_t alphabet_size = 128;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t raita_search(const std::int64_t *input, std::size_t length,
        std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 2 || length > max_frame) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_pattern)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + m) return -1;
    for (std::size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 127) return -1;

    const auto *text = input + 2;
    const auto *pattern = text + n;
    std::int64_t positions[max_text]{};
    std::size_t match_count = 0;
    if (m <= n) {
        std::size_t shifts[alphabet_size];
        std::fill_n(shifts, alphabet_size, m);
        for (std::size_t i = 0; i + 1 < m; ++i)
            shifts[static_cast<std::size_t>(pattern[i])] = m - i - 1;
        const auto middle = m / 2;
        for (std::size_t alignment = 0; alignment <= n - m;) {
            const auto last = static_cast<std::size_t>(text[alignment + m - 1]);
            bool matches = pattern[m - 1] == static_cast<std::int64_t>(last);
            if (matches) matches = pattern[0] == text[alignment];
            if (matches) matches = pattern[middle] == text[alignment + middle];
            if (matches) {
                for (std::size_t i = 1; i + 1 < m; ++i) {
                    if (pattern[i] != text[alignment + i]) { matches = false; break; }
                }
                if (matches) positions[match_count++] = static_cast<std::int64_t>(alignment);
            }
            alignment += shifts[last];
        }
    }
    const auto output_bytes = match_count * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < match_count; ++i) store_i64_le(output, i * 8, positions[i]);
    return static_cast<std::int64_t>(output_bytes);
}
