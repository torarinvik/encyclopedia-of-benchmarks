/* Test ASCII pattern presence with a Rabin-Karp rolling hash. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kBase = 256;
constexpr std::int64_t kModulus = 1000003;
}

extern "C" std::int64_t rabin_karp(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 512) return -1;
    const std::int64_t text_length_value = values[0];
    const std::int64_t pattern_length_value = values[1];
    if (text_length_value < 0 || text_length_value > 255 ||
        pattern_length_value < 0 || pattern_length_value > 255 ||
        length != static_cast<std::size_t>(2 + text_length_value + pattern_length_value)) return -1;
    for (std::size_t index = 0; index < static_cast<std::size_t>(text_length_value + pattern_length_value); ++index) {
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;
    }

    const std::size_t text_length = static_cast<std::size_t>(text_length_value);
    const std::size_t pattern_length = static_cast<std::size_t>(pattern_length_value);
    if (pattern_length == 0) return 1;
    if (pattern_length > text_length) return 0;

    std::int64_t pattern_hash = 0, rolling_hash = 0, high_power = 1;
    for (std::size_t index = 0; index < pattern_length; ++index) {
        pattern_hash = (pattern_hash * kBase + values[2 + text_length + index]) % kModulus;
        rolling_hash = (rolling_hash * kBase + values[2 + index]) % kModulus;
        if (index + 1 < pattern_length) high_power = (high_power * kBase) % kModulus;
    }
    const std::size_t last_start = text_length - pattern_length;
    for (std::size_t start = 0; start <= last_start; ++start) {
        if (rolling_hash == pattern_hash) {
            std::size_t offset = 0;
            while (offset < pattern_length &&
                   values[2 + start + offset] == values[2 + text_length + offset]) ++offset;
            if (offset == pattern_length) return 1;
        }
        if (start < last_start) {
            const std::int64_t removed = (values[2 + start] * high_power) % kModulus;
            rolling_hash = (rolling_hash - removed) % kModulus;
            if (rolling_hash < 0) rolling_hash += kModulus;
            rolling_hash = (rolling_hash * kBase + values[2 + start + pattern_length]) % kModulus;
        }
    }
    return 0;
}
