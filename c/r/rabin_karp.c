/* Test ASCII pattern presence with a Rabin-Karp rolling hash. */
#include <stddef.h>
#include <stdint.h>

#define BASE INT64_C(256)
#define MODULUS INT64_C(1000003)

int64_t rabin_karp(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 512) return -1;
    const int64_t text_length_value = values[0];
    const int64_t pattern_length_value = values[1];
    if (text_length_value < 0 || text_length_value > 255 ||
        pattern_length_value < 0 || pattern_length_value > 255 ||
        length != (size_t)(2 + text_length_value + pattern_length_value)) return -1;
    for (size_t index = 0; index < (size_t)(text_length_value + pattern_length_value); ++index) {
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;
    }

    const size_t text_length = (size_t)text_length_value;
    const size_t pattern_length = (size_t)pattern_length_value;
    if (pattern_length == 0) return 1;
    if (pattern_length > text_length) return 0;

    int64_t pattern_hash = 0, rolling_hash = 0, high_power = 1;
    for (size_t index = 0; index < pattern_length; ++index) {
        pattern_hash = (pattern_hash * BASE + values[2 + text_length + index]) % MODULUS;
        rolling_hash = (rolling_hash * BASE + values[2 + index]) % MODULUS;
        if (index + 1 < pattern_length) high_power = (high_power * BASE) % MODULUS;
    }
    const size_t last_start = text_length - pattern_length;
    for (size_t start = 0; start <= last_start; ++start) {
        if (rolling_hash == pattern_hash) {
            size_t offset = 0;
            while (offset < pattern_length &&
                   values[2 + start + offset] == values[2 + text_length + offset]) ++offset;
            if (offset == pattern_length) return 1;
        }
        if (start < last_start) {
            const int64_t removed = (values[2 + start] * high_power) % MODULUS;
            rolling_hash = (rolling_hash - removed) % MODULUS;
            if (rolling_hash < 0) rolling_hash += MODULUS;
            rolling_hash = (rolling_hash * BASE + values[2 + start + pattern_length]) % MODULUS;
        }
    }
    return 0;
}
