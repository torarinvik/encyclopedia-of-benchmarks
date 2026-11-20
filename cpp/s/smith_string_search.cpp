// Bounded all-occurrences Smith string search.
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

extern "C" std::int64_t smith_string_search(const std::int64_t *input,
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
        const auto pattern_start = 2 + n;
        std::size_t horspool[alphabet_size];
        std::size_t quick_search[alphabet_size];
        std::fill_n(horspool, alphabet_size, m);
        std::fill_n(quick_search, alphabet_size, m + 1);
        for (std::size_t i = 0; i + 1 < m; ++i)
            horspool[static_cast<std::size_t>(input[pattern_start + i])] = m - i - 1;
        for (std::size_t i = 0; i < m; ++i)
            quick_search[static_cast<std::size_t>(input[pattern_start + i])] = m - i;

        const auto last_alignment = n - m;
        for (std::size_t alignment = 0; alignment <= last_alignment;) {
            bool matches = true;
            for (std::size_t i = 0; i < m; ++i) {
                if (input[pattern_start + i] != input[2 + alignment + i]) {
                    matches = false;
                    break;
                }
            }
            if (matches) positions[match_count++] = static_cast<std::int64_t>(alignment);
            const auto end_byte = static_cast<std::size_t>(input[2 + alignment + m - 1]);
            const auto lookahead = alignment + m;
            const auto quick_shift = lookahead < n
                ? quick_search[static_cast<std::size_t>(input[2 + lookahead])] : m + 1;
            alignment += std::max(horspool[end_byte], quick_shift);
        }
    }

    const auto output_bytes = match_count * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < match_count; ++i) store_i64_le(output, i * 8, positions[i]);
    return static_cast<std::int64_t>(output_bytes);
}
