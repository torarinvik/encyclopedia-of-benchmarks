/* Case-insensitive ASCII pattern search using the Z algorithm. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxSequenceLength = 2047;
constexpr std::size_t MaxConcatLength = 2 * MaxSequenceLength + 1;
std::uint32_t fold_ascii(std::int64_t value) noexcept {
    const auto byte = static_cast<std::uint32_t>(value);
    return byte >= 'A' && byte <= 'Z' ? byte + ('a' - 'A') : byte;
}
}

extern "C" std::int64_t z_algorithm_search(const std::int64_t *values,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 2) return -1;
    if (values[0] < 0 || values[0] > MaxSequenceLength ||
        values[1] < 0 || values[1] > MaxSequenceLength) return -1;
    const auto text_length = static_cast<std::size_t>(values[0]);
    const auto pattern_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (std::size_t i = 2; i < length; ++i) if (values[i] < 0 || values[i] > 127) return -1;
    if (pattern_length == 0) {
        const auto count = text_length + 1;
        if (output_capacity < 4 * count || output == nullptr) return -2;
        for (std::size_t i = 0; i < count; ++i) {
            const auto position = static_cast<std::uint32_t>(i + 1);
            for (std::size_t b = 0; b < 4; ++b) output[4 * i + b] = static_cast<std::uint8_t>(position >> (8 * b));
        }
        return static_cast<std::int64_t>(count);
    }
    std::uint32_t sequence[MaxConcatLength]{};
    std::size_t z[MaxConcatLength]{};
    const auto total = pattern_length + 1 + text_length;
    for (std::size_t i = 0; i < pattern_length; ++i) sequence[i] = fold_ascii(values[2 + text_length + i]);
    sequence[pattern_length] = 256;
    for (std::size_t i = 0; i < text_length; ++i) sequence[pattern_length + 1 + i] = fold_ascii(values[2 + i]);
    std::size_t left = 0, right = 0;
    for (std::size_t i = 1; i < total; ++i) {
        if (i < right) { const auto remain = right - i; const auto mirror = z[i - left]; z[i] = mirror < remain ? mirror : remain; }
        while (i + z[i] < total && sequence[z[i]] == sequence[i + z[i]]) ++z[i];
        if (i + z[i] > right) { left = i; right = i + z[i]; }
    }
    std::size_t count = 0;
    for (std::size_t i = pattern_length + 1; i < total; ++i) if (z[i] >= pattern_length) ++count;
    if (output_capacity < 4 * count || (count != 0 && output == nullptr)) return -2;
    std::size_t write = 0;
    for (std::size_t i = pattern_length + 1; i < total; ++i) if (z[i] >= pattern_length) {
        const auto position = static_cast<std::uint32_t>(i - pattern_length);
        for (std::size_t b = 0; b < 4; ++b) output[4 * write + b] = static_cast<std::uint8_t>(position >> (8 * b));
        ++write;
    }
    return static_cast<std::int64_t>(count);
}
