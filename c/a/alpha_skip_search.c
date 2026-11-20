#include <stddef.h>
#include <stdint.h>

#define ALPHA_SKIP_MAX_TEXT 4096
#define ALPHA_SKIP_MAX_PATTERN 128
#define ALPHA_SKIP_MAX_INPUT_LENGTH 4227
#define ALPHA_SKIP_BUCKETS 64

int64_t alpha_skip_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > ALPHA_SKIP_MAX_INPUT_LENGTH) return -1;
    const int64_t raw_text_length = input[0];
    const int64_t raw_pattern_length = input[1];
    if (raw_text_length < 0 || raw_text_length > ALPHA_SKIP_MAX_TEXT ||
        raw_pattern_length < 1 || raw_pattern_length > ALPHA_SKIP_MAX_PATTERN)
        return -1;
    const size_t text_length = (size_t)raw_text_length;
    const size_t pattern_length = (size_t)raw_pattern_length;
    if (length != 2 + text_length + pattern_length) return -1;

    uint8_t text[ALPHA_SKIP_MAX_TEXT];
    uint8_t pattern[ALPHA_SKIP_MAX_PATTERN];
    for (size_t i = 0; i < text_length; ++i) {
        const int64_t symbol = input[2 + i];
        if (symbol < 0 || symbol > 3) return -1;
        text[i] = (uint8_t)symbol;
    }
    for (size_t i = 0; i < pattern_length; ++i) {
        const int64_t symbol = input[2 + text_length + i];
        if (symbol < 0 || symbol > 3) return -1;
        pattern[i] = (uint8_t)symbol;
    }
    if (text_length < pattern_length) return 0;

    size_t factor_length = 1;
    size_t bucket_count = 4;
    while (bucket_count * 4 <= pattern_length) {
        ++factor_length;
        bucket_count *= 4;
    }
    const size_t shift = pattern_length - factor_length + 1;
    size_t power = 1;
    for (size_t i = 1; i < factor_length; ++i) power *= 4;

    int head[ALPHA_SKIP_BUCKETS];
    int next_factor[ALPHA_SKIP_MAX_PATTERN];
    for (size_t code = 0; code < bucket_count; ++code) head[code] = -1;
    int factor_code = 0;
    for (size_t i = 0; i < factor_length; ++i)
        factor_code = factor_code * 4 + pattern[i];
    for (size_t position = 0; position + factor_length <= pattern_length; ++position) {
        next_factor[position] = head[factor_code];
        head[factor_code] = (int)position;
        if (position + factor_length < pattern_length) {
            factor_code = (factor_code - pattern[position] * (int)power) * 4
                        + pattern[position + factor_length];
        }
    }

    int64_t match_count = 0;
    int64_t offset_sum = 0;
    int64_t offset_xor = 0;
    int text_factor_code = 0;
    for (size_t i = 0; i < factor_length; ++i)
        text_factor_code = text_factor_code * 4 + text[i];
    const size_t last_factor_start = text_length - factor_length;
    for (size_t sample_start = 0; sample_start <= last_factor_start; ++sample_start) {
        if (sample_start % shift == 0) {
            for (int position = head[text_factor_code]; position >= 0; position = next_factor[position]) {
                const int64_t candidate = (int64_t)sample_start - position;
                if (candidate < 0 || candidate + raw_pattern_length > raw_text_length) continue;
                size_t compared = 0;
                while (compared < pattern_length &&
                       text[(size_t)candidate + compared] == pattern[compared])
                    ++compared;
                if (compared == pattern_length) {
                    ++match_count;
                    offset_sum += candidate;
                    offset_xor ^= candidate;
                }
            }
        }
        if (sample_start < last_factor_start) {
            text_factor_code = (text_factor_code - text[sample_start] * (int)power) * 4
                             + text[sample_start + factor_length];
        }
    }

    const uint64_t packed = ((uint64_t)match_count << 36)
                          | ((uint64_t)offset_sum << 12)
                          | (uint64_t)offset_xor;
    return (int64_t)packed;
}
