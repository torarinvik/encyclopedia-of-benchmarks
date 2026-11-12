#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT_LENGTH = 32, MAX_INPUT_LENGTH = 34, MAX_ALPHABET = 256 };

static void induce(const int32_t *symbols, int length, int upper,
                   const uint8_t *is_s, const int32_t *sum_s,
                   const int32_t *sum_l, const int32_t *lms, int lms_count,
                   int32_t *suffixes)
{
    int32_t bucket[MAX_ALPHABET + 2];
    for (int i = 0; i < length; ++i) suffixes[i] = -1;
    for (int i = 0; i <= upper + 1; ++i) bucket[i] = sum_s[i];
    for (int i = 0; i < lms_count; ++i) {
        const int position = lms[i];
        suffixes[bucket[symbols[position]]++] = position;
    }
    for (int i = 0; i <= upper + 1; ++i) bucket[i] = sum_l[i];
    for (int i = 0; i < length; ++i) {
        const int position = suffixes[i];
        if (position > 0 && !is_s[position - 1]) {
            const int symbol = symbols[position - 1];
            suffixes[bucket[symbol]++] = position - 1;
        }
    }
    for (int i = 0; i <= upper + 1; ++i) bucket[i] = sum_l[i];
    for (int i = length - 1; i >= 0; --i) {
        const int position = suffixes[i];
        if (position > 0 && is_s[position - 1]) {
            const int symbol = symbols[position - 1] + 1;
            suffixes[--bucket[symbol]] = position - 1;
        }
    }
}

static int same_lms_substring(const int32_t *symbols, const uint8_t *is_s,
                              const int32_t *lms_map, int length,
                              int left, int right)
{
    if (left == right) return 1;
    for (int offset = 0;; ++offset) {
        const int a = left + offset, b = right + offset;
        if (a >= length || b >= length || symbols[a] != symbols[b] || is_s[a] != is_s[b])
            return 0;
        const int a_lms = offset > 0 && lms_map[a] >= 0;
        const int b_lms = offset > 0 && lms_map[b] >= 0;
        if (a_lms || b_lms) return a_lms && b_lms;
    }
}

static void sais(const int32_t *symbols, int length, int upper, int32_t *suffixes)
{
    if (length == 0) return;
    if (length <= 2) {
        for (int i = 0; i < length; ++i) suffixes[i] = i;
        if (length == 2 && (symbols[0] >= symbols[1])) {
            suffixes[0] = 1;
            suffixes[1] = 0;
        }
        return;
    }

    uint8_t is_s[MAX_TEXT_LENGTH + 1] = {0};
    is_s[length - 1] = 1;
    for (int i = length - 2; i >= 0; --i)
        is_s[i] = (uint8_t)(symbols[i] < symbols[i + 1]
            || (symbols[i] == symbols[i + 1] && is_s[i + 1]));

    int32_t lms_map[MAX_TEXT_LENGTH + 2];
    int32_t lms[MAX_TEXT_LENGTH + 1];
    for (int i = 0; i <= length; ++i) lms_map[i] = -1;
    int lms_count = 0;
    for (int i = 1; i < length; ++i) {
        if (!is_s[i - 1] && is_s[i]) {
            lms_map[i] = lms_count;
            lms[lms_count++] = i;
        }
    }

    int32_t sum_s[MAX_ALPHABET + 2] = {0};
    int32_t sum_l[MAX_ALPHABET + 2] = {0};
    for (int i = 0; i < length; ++i) {
        const int symbol = symbols[i];
        if (is_s[i]) ++sum_l[symbol + 1];
        else ++sum_s[symbol];
    }
    for (int symbol = 0; symbol <= upper; ++symbol) {
        sum_s[symbol] += sum_l[symbol];
        sum_l[symbol + 1] += sum_s[symbol];
    }

    induce(symbols, length, upper, is_s, sum_s, sum_l, lms, lms_count, suffixes);
    int32_t sorted_lms[MAX_TEXT_LENGTH + 1];
    int sorted_count = 0;
    for (int i = 0; i < length; ++i) {
        const int position = suffixes[i];
        if (position >= 0 && lms_map[position] >= 0) sorted_lms[sorted_count++] = position;
    }

    int32_t reduced[MAX_TEXT_LENGTH + 1];
    int reduced_upper = 0;
    for (int i = 0; i < sorted_count; ++i) {
        if (i > 0 && !same_lms_substring(symbols, is_s, lms_map, length,
                                         sorted_lms[i - 1], sorted_lms[i]))
            ++reduced_upper;
        reduced[lms_map[sorted_lms[i]]] = reduced_upper;
    }
    int32_t reduced_order[MAX_TEXT_LENGTH + 1];
    if (reduced_upper + 1 == sorted_count) {
        for (int i = 0; i < sorted_count; ++i) reduced_order[reduced[i]] = i;
    } else {
        sais(reduced, sorted_count, reduced_upper, reduced_order);
    }
    int32_t ordered_lms[MAX_TEXT_LENGTH + 1];
    for (int i = 0; i < sorted_count; ++i) ordered_lms[i] = lms[reduced_order[i]];
    induce(symbols, length, upper, is_s, sum_s, sum_l,
           ordered_lms, sorted_count, suffixes);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t suffix_array_sais(const int64_t *values, size_t length,
                          uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_TEXT_LENGTH) return -1;
    const int count = (int)count_value;
    if (length != (size_t)count + 1) return -1;
    for (int i = 0; i < count; ++i)
        if (values[i + 1] < 0 || values[i + 1] > 255) return -1;

    const size_t output_bytes = (size_t)count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    int32_t symbols[MAX_TEXT_LENGTH + 1];
    for (int i = 0; i < count; ++i) symbols[i] = (int32_t)values[i + 1] + 1;
    symbols[count] = 0;
    int32_t suffixes[MAX_TEXT_LENGTH + 1];
    sais(symbols, count + 1, 256, suffixes);
    int out = 0;
    for (int i = 0; i <= count; ++i) {
        if (suffixes[i] == count) continue;
        store_i64_le(output, (size_t)out++ * 8, suffixes[i]);
    }
    return (int64_t)output_bytes;
}
