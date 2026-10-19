// Modified derivative of MiBench bmhsrch.c; public domain by Raymond Gardner (7/92).
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 128;
constexpr std::size_t max_pattern = 32;

void store_i64_le(std::uint8_t *output, std::int64_t value) noexcept {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i)
        output[i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t mibench_office_stringsearch_bmh(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > 2 + max_text + max_pattern) return -1;
    const std::int64_t text_len_value = input[0], pattern_len_value = input[1];
    if (text_len_value < 0 || text_len_value > static_cast<std::int64_t>(max_text) ||
        pattern_len_value < 1 || pattern_len_value > static_cast<std::int64_t>(max_pattern)) return -1;
    const auto text_len = static_cast<std::size_t>(text_len_value);
    const auto pattern_len = static_cast<std::size_t>(pattern_len_value);
    if (length != 2 + text_len + pattern_len) return -1;
    std::array<std::uint8_t, max_text> text{};
    std::array<std::uint8_t, max_pattern> pattern{};
    for (std::size_t i = 0; i < text_len + pattern_len; ++i) {
        const std::int64_t value = input[2 + i];
        if (value < 32 || value > 126) return -1;
        if (i < text_len) text[i] = static_cast<std::uint8_t>(value);
        else pattern[i - text_len] = static_cast<std::uint8_t>(value);
    }
    std::array<std::size_t, 256> shift{};
    shift.fill(pattern_len);
    for (std::size_t i = 0; i + 1 < pattern_len; ++i)
        shift[pattern[i]] = pattern_len - i - 1;
    std::int64_t match = -1;
    if (pattern_len <= text_len) {
        std::size_t start = 0;
        while (start <= text_len - pattern_len) {
            std::size_t j = pattern_len;
            while (j > 0 && text[start + j - 1] == pattern[j - 1]) --j;
            if (j == 0) { match = static_cast<std::int64_t>(start); break; }
            start += shift[text[start + pattern_len - 1]];
        }
    }
    if (output == nullptr || output_capacity < 8) return -2;
    store_i64_le(output, match);
    return 8;
}
