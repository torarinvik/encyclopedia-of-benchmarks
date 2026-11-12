#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT_LENGTH = 64, MAX_PATTERN_LENGTH = 32, MAX_INPUT_LENGTH = 99 };

static void maximal_suffix(const int64_t *pattern, int length, int reverse_order,
                           int *critical, int *period)
{
    int maximal = -1;
    int candidate = 0;
    int offset = 1;
    int candidate_period = 1;
    while (candidate + offset < length) {
        const int64_t a = pattern[candidate + offset];
        const int64_t b = pattern[maximal + offset];
        const int precedes = reverse_order ? a > b : a < b;
        if (precedes) {
            candidate += offset;
            offset = 1;
            candidate_period = candidate - maximal;
        } else if (a == b) {
            if (offset != candidate_period) ++offset;
            else {
                candidate += candidate_period;
                offset = 1;
            }
        } else {
            maximal = candidate;
            candidate = maximal + 1;
            offset = 1;
            candidate_period = 1;
        }
    }
    *critical = maximal;
    *period = candidate_period;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t crochemore_perrin_two_way(const int64_t *values, size_t length,
                                  uint8_t *output, size_t capacity);

int64_t crochemore_perrin_two_way(const int64_t *values, size_t length,
                                  uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 0 || values[0] > MAX_TEXT_LENGTH
        || values[1] < 0 || values[1] > MAX_PATTERN_LENGTH) return -1;
    const int text_length = (int)values[0];
    const int pattern_length = (int)values[1];
    if (length != (size_t)(2 + text_length + pattern_length)) return -1;
    const int64_t *text = values + 2;
    const int64_t *pattern = text + text_length;
    for (int i = 0; i < text_length; ++i)
        if (text[i] < 0 || text[i] > 255) return -1;
    for (int i = 0; i < pattern_length; ++i)
        if (pattern[i] < 0 || pattern[i] > 255) return -1;

    int64_t matches[MAX_TEXT_LENGTH + 1];
    int match_count = 0;
    if (pattern_length == 0) {
        for (int i = 0; i <= text_length; ++i) matches[match_count++] = i;
    } else if (pattern_length <= text_length) {
        int critical_a, period_a, critical_b, period_b;
        maximal_suffix(pattern, pattern_length, 0, &critical_a, &period_a);
        maximal_suffix(pattern, pattern_length, 1, &critical_b, &period_b);
        int critical, period;
        if (critical_a > critical_b) { critical = critical_a; period = period_a; }
        else { critical = critical_b; period = period_b; }

        int periodic = period + critical + 1 <= pattern_length;
        for (int i = 0; periodic && i <= critical; ++i)
            if (pattern[i] != pattern[i + period]) periodic = 0;
        int shift;
        if (periodic) shift = period;
        else shift = (critical > pattern_length - critical - 1
                      ? critical : pattern_length - critical - 1) + 1;

        int memory = -1;
        int start = 0;
        while (start <= text_length - pattern_length) {
            int index = periodic && memory > critical ? memory + 1 : critical + 1;
            while (index < pattern_length && pattern[index] == text[start + index]) ++index;
            if (index >= pattern_length) {
                index = critical;
                while (index > memory && pattern[index] == text[start + index]) --index;
                if (index <= memory) matches[match_count++] = start;
                start += shift;
                memory = periodic ? pattern_length - period - 1 : -1;
            } else {
                start += index - critical;
                memory = -1;
            }
        }
    }

    const size_t output_bytes = (size_t)match_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (int i = 0; i < match_count; ++i)
        store_i64_le(output, (size_t)i * 8, matches[i]);
    return (int64_t)output_bytes;
}
