#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 256;
constexpr std::size_t max_pattern_length = 32;
constexpr std::size_t alphabet_size = 128;
constexpr std::size_t max_parseable_input_length = 2 + max_text_length + max_pattern_length + 1;

std::size_t next_state(const std::int64_t *pattern, std::size_t pattern_length,
                       std::size_t state, std::int64_t symbol) {
    if (state < pattern_length && symbol == pattern[state]) return state + 1;
    for (std::size_t candidate = state; candidate > 0; --candidate) {
        if (pattern[candidate - 1] != symbol) continue;
        bool prefix_matches = true;
        for (std::size_t i = 0; i + 1 < candidate; ++i) {
            if (pattern[i] != pattern[state - candidate + i + 1]) {
                prefix_matches = false;
                break;
            }
        }
        if (prefix_matches) return candidate;
    }
    return 0;
}

void store_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
} // namespace

extern "C" std::int64_t string_match_finite_automata(const std::int64_t *values,
                                                      std::size_t length,
                                                      std::uint8_t *output,
                                                      std::size_t capacity) {
    if (values == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    const auto raw_text_length = values[0];
    const auto raw_pattern_length = values[1];
    if (raw_text_length < 0 || raw_text_length > static_cast<std::int64_t>(max_text_length) ||
        raw_pattern_length < 1 || raw_pattern_length > static_cast<std::int64_t>(max_pattern_length) ||
        length != 2 + static_cast<std::size_t>(raw_text_length) +
                      static_cast<std::size_t>(raw_pattern_length)) return -1;
    const auto text_length = static_cast<std::size_t>(raw_text_length);
    const auto pattern_length = static_cast<std::size_t>(raw_pattern_length);
    for (std::size_t i = 0; i < text_length + pattern_length; ++i)
        if (values[2 + i] < 0 || values[2 + i] >= static_cast<std::int64_t>(alphabet_size)) return -1;

    const auto *text = values + 2;
    const auto *pattern = text + text_length;
    std::array<std::array<std::int32_t, alphabet_size>, max_pattern_length + 1> transitions{};
    for (std::size_t state = 0; state <= pattern_length; ++state)
        for (std::size_t symbol = 0; symbol < alphabet_size; ++symbol)
            transitions[state][symbol] =
                static_cast<std::int32_t>(next_state(pattern, pattern_length, state,
                                                     static_cast<std::int64_t>(symbol)));

    std::array<std::int32_t, max_text_length> matches{};
    std::size_t match_count = 0;
    std::size_t state = 0;
    for (std::size_t index = 0; index < text_length; ++index) {
        state = static_cast<std::size_t>(transitions[state][static_cast<std::size_t>(text[index])]);
        if (state == pattern_length)
            matches[match_count++] = static_cast<std::int32_t>(index + 1 - pattern_length);
    }

    const auto byte_count = 4 * match_count;
    if (output == nullptr || capacity < byte_count) return -2;
    for (std::size_t index = 0; index < match_count; ++index)
        store_i32_le(output, 4 * index, matches[index]);
    return static_cast<std::int64_t>(byte_count);
}
