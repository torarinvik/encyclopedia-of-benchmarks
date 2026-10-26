#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxText = 24;
constexpr std::size_t kMaxPattern = 8;
constexpr std::size_t kAlphabet = 16;
constexpr std::size_t kMaxOutputBytes = 200;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

void predecessor_code(const std::int64_t *symbols, std::size_t length,
                      std::int64_t *code)
{
    std::int64_t last[kAlphabet];
    for (std::size_t symbol = 0; symbol < kAlphabet; ++symbol) last[symbol] = -1;
    for (std::size_t index = 0; index < length; ++index) {
        const auto symbol = static_cast<std::size_t>(symbols[index]);
        code[index] = last[symbol] < 0 ? 0 : static_cast<std::int64_t>(index) - last[symbol];
        last[symbol] = static_cast<std::int64_t>(index);
    }
}
}

extern "C" std::int64_t parameterized_pattern_matching(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || length > 2 + kMaxText + kMaxPattern) return -1;
    const auto text_length_value = input[0];
    const auto pattern_length_value = input[1];
    if (text_length_value < 0 || text_length_value > static_cast<std::int64_t>(kMaxText) ||
        pattern_length_value < 1 || pattern_length_value > static_cast<std::int64_t>(kMaxPattern)) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    const auto pattern_length = static_cast<std::size_t>(pattern_length_value);
    if (length != 2 + text_length + pattern_length) return -1;
    for (std::size_t index = 2; index < length; ++index) {
        if (input[index] < 0 || input[index] >= static_cast<std::int64_t>(kAlphabet)) return -1;
    }

    std::int64_t pattern_code[kMaxPattern] = {};
    predecessor_code(input + 2 + text_length, pattern_length, pattern_code);
    std::size_t matches[kMaxText] = {};
    std::size_t match_count = 0;
    if (pattern_length <= text_length) {
        for (std::size_t start = 0; start <= text_length - pattern_length; ++start) {
            std::int64_t window_code[kMaxPattern] = {};
            predecessor_code(input + 2 + start, pattern_length, window_code);
            std::size_t index = 0;
            while (index < pattern_length && pattern_code[index] == window_code[index]) ++index;
            if (index == pattern_length) matches[match_count++] = start;
        }
    }

    const std::size_t output_bytes = 8 * (match_count + 1);
    if (output == nullptr || capacity < output_bytes) return -2;
    std::uint8_t staged[kMaxOutputBytes] = {};
    store_i64_le(staged, 0, static_cast<std::int64_t>(match_count));
    for (std::size_t index = 0; index < match_count; ++index) {
        store_i64_le(staged, 8 * (index + 1), static_cast<std::int64_t>(matches[index]));
    }
    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_bytes);
}
