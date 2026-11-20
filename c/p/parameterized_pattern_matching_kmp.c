#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 64
#define MAX_PATTERN 16
#define MAX_ALPHABET 16
#define MAX_PARSEABLE_INPUT 84
#define MAX_OUTPUT_BYTES 520

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static int pattern_compare(const int64_t *pattern, const int *previous,
                           const int *previous_at, int current, int prefix_pos)
{
    const int prior = previous[current];
    if (prior < 0 || current - prior > prefix_pos) {
        return previous_at[prefix_pos] < 0;
    }
    const int distance = current - prior;
    return pattern[prefix_pos] == pattern[prefix_pos - distance];
}

static int text_compare(const int64_t *text, int text_pos, int pattern_pos,
                        const int *previous, const int *last_text)
{
    const int prior = previous[pattern_pos];
    const int64_t symbol = text[text_pos];
    if (prior < 0) return last_text[(size_t)symbol] < text_pos - pattern_pos;
    const int distance = pattern_pos - prior;
    return symbol == text[text_pos - distance];
}

int64_t parameterized_pattern_matching_kmp(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    const int64_t alphabet_value = input[2];
    if (n_value < 0 || n_value > MAX_TEXT || m_value < 1 || m_value > MAX_PATTERN ||
        alphabet_value < 1 || alphabet_value > MAX_ALPHABET) return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    const size_t alphabet_size = (size_t)alphabet_value;
    if (length != 3 + n + m) return -1;
    for (size_t index = 3; index < length; ++index) {
        if (input[index] < 0 || (uint64_t)input[index] >= alphabet_size) return -1;
    }
    if (output == NULL && capacity != 0) return -2;

    const int64_t *text = input + 3;
    const int64_t *pattern = text + n;
    int previous[MAX_PATTERN];
    int previous_at[MAX_PATTERN];
    int last_pattern[MAX_ALPHABET];
    int failure[MAX_PATTERN] = {0};
    for (size_t symbol = 0; symbol < MAX_ALPHABET; ++symbol) last_pattern[symbol] = -1;
    for (int index = 0; index < (int)m; ++index) {
        const size_t symbol = (size_t)pattern[index];
        previous[index] = last_pattern[symbol];
        previous_at[index] = previous[index];
        last_pattern[symbol] = index;
    }

    for (int current = 1; current < (int)m; ++current) {
        int matched = failure[current - 1];
        while (matched > 0 && !pattern_compare(pattern, previous, previous_at,
                                                current, matched)) {
            matched = failure[matched - 1];
        }
        if (pattern_compare(pattern, previous, previous_at, current, matched)) ++matched;
        failure[current] = matched;
    }

    int last_text[MAX_ALPHABET];
    for (size_t symbol = 0; symbol < MAX_ALPHABET; ++symbol) last_text[symbol] = -1;
    int64_t matches[MAX_TEXT];
    size_t match_count = 0;
    int matched = 0;
    if (m <= n) {
        for (int text_pos = 0; text_pos < (int)n; ++text_pos) {
            for (;;) {
                const int equal = text_compare(text, text_pos, matched, previous, last_text);
                if (equal) {
                    ++matched;
                    if (matched == (int)m) {
                        matches[match_count++] = (int64_t)(text_pos + 1 - (int)m);
                        matched = failure[m - 1];
                    }
                    break;
                }
                if (matched == 0) break;
                matched = failure[matched - 1];
            }
            last_text[(size_t)text[text_pos]] = text_pos;
        }
    }

    const size_t output_bytes = 8 * (match_count + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    store_i64_le(staged, 0, (int64_t)match_count);
    for (size_t index = 0; index < match_count; ++index) {
        store_i64_le(staged, 8 * (index + 1), matches[index]);
    }
    for (size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return (int64_t)output_bytes;
}
