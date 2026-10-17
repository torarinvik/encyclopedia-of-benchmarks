#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 256;
constexpr std::size_t max_pattern_length = 64;
constexpr std::size_t max_input_length = 322;
}

extern "C" std::int64_t kmp_all_occurrences(const std::int64_t* values, std::size_t length,
                                             std::uint8_t* output, std::size_t capacity)
{
    if (values == nullptr || length < 2 || length > max_input_length) return -1;
    const auto text_length_value = values[0];
    const auto pattern_length_value = values[1];
    if (text_length_value < 0 || text_length_value > static_cast<std::int64_t>(max_text_length) ||
        pattern_length_value < 1 || pattern_length_value > static_cast<std::int64_t>(max_pattern_length)) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    const auto pattern_length = static_cast<std::size_t>(pattern_length_value);
    if (length != 2 + text_length + pattern_length) return -1;
    const auto pattern_offset = 2 + text_length;
    for (std::size_t i = 0; i < text_length + pattern_length; ++i)
        if (values[2 + i] < 0 || values[2 + i] > 127) return -1;

    std::array<std::size_t, max_pattern_length> prefix{};
    for (std::size_t i = 1; i < pattern_length; ++i) {
        auto matched = prefix[i - 1];
        while (matched > 0 && values[pattern_offset + i] != values[pattern_offset + matched])
            matched = prefix[matched - 1];
        if (values[pattern_offset + i] == values[pattern_offset + matched]) ++matched;
        prefix[i] = matched;
    }

    std::array<std::size_t, max_text_length> matches{};
    std::size_t match_count = 0, matched = 0;
    for (std::size_t i = 0; i < text_length; ++i) {
        while (matched > 0 && values[2 + i] != values[pattern_offset + matched])
            matched = prefix[matched - 1];
        if (values[2 + i] == values[pattern_offset + matched]) ++matched;
        if (matched == pattern_length) {
            matches[match_count++] = i + 1 - pattern_length;
            matched = prefix[matched - 1];
        }
    }

    const auto output_bytes = match_count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < match_count; ++i) {
        const auto bits = static_cast<std::uint64_t>(matches[i]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[i * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(output_bytes);
}
