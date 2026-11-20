// All-occurrences Turbo Boyer–Moore search over bounded ASCII byte strings.
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

void good_suffix(const std::int64_t *pattern, std::size_t length, std::size_t *shift)
{
    std::size_t suffix[max_pattern]{};
    suffix[length - 1] = length;
    auto g = static_cast<std::ptrdiff_t>(length) - 1;
    std::ptrdiff_t f = 0;
    for (auto index = static_cast<std::ptrdiff_t>(length) - 2; index >= 0; --index) {
        if (index > g && suffix[static_cast<std::size_t>(index + static_cast<std::ptrdiff_t>(length) - 1 - f)]
                < static_cast<std::size_t>(index - g)) {
            suffix[static_cast<std::size_t>(index)] =
                suffix[static_cast<std::size_t>(index + static_cast<std::ptrdiff_t>(length) - 1 - f)];
        } else {
            if (index < g) g = index;
            f = index;
            while (g >= 0 && pattern[static_cast<std::size_t>(g)] ==
                    pattern[static_cast<std::size_t>(g + static_cast<std::ptrdiff_t>(length) - 1 - f)]) --g;
            suffix[static_cast<std::size_t>(index)] = static_cast<std::size_t>(f - g);
        }
    }
    std::fill_n(shift, length, length);
    std::size_t border = 0;
    for (auto index = static_cast<std::ptrdiff_t>(length) - 1; index >= 0; --index) {
        if (suffix[static_cast<std::size_t>(index)] == static_cast<std::size_t>(index) + 1) {
            while (border < length - 1 - static_cast<std::size_t>(index)) {
                if (shift[border] == length) shift[border] = length - 1 - static_cast<std::size_t>(index);
                ++border;
            }
        }
    }
    for (std::size_t index = 0; index + 1 < length; ++index)
        shift[length - 1 - suffix[index]] = length - 1 - index;
}
} // namespace

extern "C" std::int64_t turbo_boyer_moore_search(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 2 || length > max_frame) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_pattern)) return -1;
    const auto text_length = static_cast<std::size_t>(input[0]);
    const auto pattern_length = static_cast<std::size_t>(input[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (std::size_t index = 0; index < text_length + pattern_length; ++index)
        if (input[2 + index] < 0 || input[2 + index] >= static_cast<std::int64_t>(alphabet_size)) return -1;

    const auto *text = input + 2;
    const auto *pattern = text + text_length;
    std::int64_t positions[max_text]{};
    std::size_t match_count = 0;
    if (pattern_length <= text_length) {
        std::size_t bad_character[alphabet_size];
        std::size_t good[ max_pattern ];
        std::fill_n(bad_character, alphabet_size, pattern_length);
        for (std::size_t index = 0; index + 1 < pattern_length; ++index)
            bad_character[static_cast<std::size_t>(pattern[index])] = pattern_length - index - 1;
        good_suffix(pattern, pattern_length, good);

        std::size_t alignment = 0, remembered = 0, shift = pattern_length;
        while (alignment <= text_length - pattern_length) {
            auto index = static_cast<std::ptrdiff_t>(pattern_length) - 1;
            while (index >= 0 && pattern[static_cast<std::size_t>(index)] ==
                    text[alignment + static_cast<std::size_t>(index)]) {
                --index;
                if (remembered != 0 && index == static_cast<std::ptrdiff_t>(pattern_length) - 1 -
                        static_cast<std::ptrdiff_t>(shift)) index -= static_cast<std::ptrdiff_t>(remembered);
            }
            if (index < 0) {
                positions[match_count++] = static_cast<std::int64_t>(alignment);
                shift = good[0];
                remembered = pattern_length - shift;
            } else {
                const auto matched_suffix = pattern_length - 1 - static_cast<std::size_t>(index);
                const auto turbo_shift = static_cast<std::ptrdiff_t>(remembered) -
                    static_cast<std::ptrdiff_t>(matched_suffix);
                const auto bad_shift = static_cast<std::ptrdiff_t>(bad_character[
                    static_cast<std::size_t>(text[alignment + static_cast<std::size_t>(index)])]) -
                    static_cast<std::ptrdiff_t>(pattern_length) + 1 + index;
                const auto gs = good[static_cast<std::size_t>(index)];
                auto chosen = std::max({turbo_shift, bad_shift, static_cast<std::ptrdiff_t>(gs)});
                shift = static_cast<std::size_t>(chosen);
                if (shift == gs) {
                    remembered = std::min(pattern_length - shift, matched_suffix);
                } else {
                    if (turbo_shift < bad_shift) shift = std::max(shift, remembered + 1);
                    remembered = 0;
                }
            }
            alignment += shift;
        }
    }
    const auto output_bytes = match_count * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < match_count; ++index)
        store_i64_le(output, index * 8, positions[index]);
    return static_cast<std::int64_t>(output_bytes);
}
