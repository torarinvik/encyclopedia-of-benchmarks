#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 4096;
constexpr std::size_t max_pattern = 128;
constexpr std::size_t max_input_length = 4227;
constexpr std::size_t max_buckets = 64;
} // namespace

extern "C" std::int64_t alpha_skip_search(const std::int64_t *input,
                                            std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t raw_text_length = input[0];
    const std::int64_t raw_pattern_length = input[1];
    if (raw_text_length < 0 || raw_text_length > static_cast<std::int64_t>(max_text) ||
        raw_pattern_length < 1 || raw_pattern_length > static_cast<std::int64_t>(max_pattern))
        return -1;
    const std::size_t text_length = static_cast<std::size_t>(raw_text_length);
    const std::size_t pattern_length = static_cast<std::size_t>(raw_pattern_length);
    if (length != 2 + text_length + pattern_length) return -1;

    std::uint8_t text[max_text]{};
    std::uint8_t pattern[max_pattern]{};
    for (std::size_t i = 0; i < text_length; ++i) {
        const std::int64_t symbol = input[2 + i];
        if (symbol < 0 || symbol > 3) return -1;
        text[i] = static_cast<std::uint8_t>(symbol);
    }
    for (std::size_t i = 0; i < pattern_length; ++i) {
        const std::int64_t symbol = input[2 + text_length + i];
        if (symbol < 0 || symbol > 3) return -1;
        pattern[i] = static_cast<std::uint8_t>(symbol);
    }
    if (text_length < pattern_length) return 0;

    std::size_t factor_length = 1;
    std::size_t bucket_count = 4;
    while (bucket_count * 4 <= pattern_length) {
        ++factor_length;
        bucket_count *= 4;
    }
    const std::size_t shift = pattern_length - factor_length + 1;
    int power = 1;
    for (std::size_t i = 1; i < factor_length; ++i) power *= 4;

    int head[max_buckets];
    int next_factor[max_pattern];
    for (std::size_t code = 0; code < bucket_count; ++code) head[code] = -1;
    int factor_code = 0;
    for (std::size_t i = 0; i < factor_length; ++i)
        factor_code = factor_code * 4 + pattern[i];
    for (std::size_t position = 0; position + factor_length <= pattern_length; ++position) {
        next_factor[position] = head[factor_code];
        head[factor_code] = static_cast<int>(position);
        if (position + factor_length < pattern_length) {
            factor_code = (factor_code - pattern[position] * power) * 4
                        + pattern[position + factor_length];
        }
    }

    std::int64_t match_count = 0;
    std::int64_t offset_sum = 0;
    std::int64_t offset_xor = 0;
    int text_factor_code = 0;
    for (std::size_t i = 0; i < factor_length; ++i)
        text_factor_code = text_factor_code * 4 + text[i];
    const std::size_t last_factor_start = text_length - factor_length;
    for (std::size_t sample_start = 0; sample_start <= last_factor_start; ++sample_start) {
        if (sample_start % shift == 0) {
            for (int position = head[text_factor_code]; position >= 0;
                 position = next_factor[position]) {
                const std::int64_t candidate = static_cast<std::int64_t>(sample_start) - position;
                if (candidate < 0 || candidate + raw_pattern_length > raw_text_length) continue;
                std::size_t compared = 0;
                while (compared < pattern_length &&
                       text[static_cast<std::size_t>(candidate) + compared] == pattern[compared])
                    ++compared;
                if (compared == pattern_length) {
                    ++match_count;
                    offset_sum += candidate;
                    offset_xor ^= candidate;
                }
            }
        }
        if (sample_start < last_factor_start) {
            text_factor_code = (text_factor_code - text[sample_start] * power) * 4
                             + text[sample_start + factor_length];
        }
    }

    const std::uint64_t packed = (static_cast<std::uint64_t>(match_count) << 36)
                               | (static_cast<std::uint64_t>(offset_sum) << 12)
                               | static_cast<std::uint64_t>(offset_xor);
    return static_cast<std::int64_t>(packed);
}
