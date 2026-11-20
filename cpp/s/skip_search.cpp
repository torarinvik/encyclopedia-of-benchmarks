#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 4096;
constexpr std::size_t max_pattern = 128;
constexpr std::size_t max_input = 4227;
constexpr std::size_t alphabet = 4;
}

extern "C" std::int64_t skip_search(const std::int64_t* input,
                                     std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const std::int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > static_cast<std::int64_t>(max_text) ||
        m64 < 1 || m64 > static_cast<std::int64_t>(max_pattern)) return -1;
    const std::size_t n = static_cast<std::size_t>(n64);
    const std::size_t m = static_cast<std::size_t>(m64);
    if (length != 2 + n + m) return -1;

    std::array<std::uint8_t, max_text> text{};
    std::array<std::uint8_t, max_pattern> pattern{};
    for (std::size_t q = 0; q < n; ++q) {
        const std::int64_t value = input[2 + q];
        if (value < 0 || value >= static_cast<std::int64_t>(alphabet)) return -1;
        text[q] = static_cast<std::uint8_t>(value);
    }
    std::array<std::array<int, max_pattern>, alphabet> positions{};
    std::array<std::size_t, alphabet> bucket_size{};
    for (std::size_t q = 0; q < m; ++q) {
        const std::int64_t value = input[2 + n + q];
        if (value < 0 || value >= static_cast<std::int64_t>(alphabet)) return -1;
        pattern[q] = static_cast<std::uint8_t>(value);
        const std::size_t symbol = static_cast<std::size_t>(value);
        positions[symbol][bucket_size[symbol]++] = static_cast<int>(q);
    }

    std::int64_t count = 0, offset_sum = 0, offset_xor = 0;
    for (std::size_t sample = m - 1; sample < n; sample += m) {
        const std::size_t symbol = text[sample];
        for (std::size_t item = 0; item < bucket_size[symbol]; ++item) {
            const std::size_t pattern_position = static_cast<std::size_t>(positions[symbol][item]);
            if (sample < pattern_position) continue;
            const std::size_t start = sample - pattern_position;
            if (start > n - m) continue;
            std::size_t matched = 0;
            while (matched < m && text[start + matched] == pattern[matched]) ++matched;
            if (matched == m) {
                ++count;
                offset_sum += static_cast<std::int64_t>(start);
                offset_xor ^= static_cast<std::int64_t>(start);
            }
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
