#include <stddef.h>
#include <stdint.h>

#define MAX_STRINGS 32
#define MAX_STRING_LENGTH 16
#define MAX_INPUT_WORDS (1 + MAX_STRINGS * (1 + MAX_STRING_LENGTH))
#define MAX_PARSEABLE_INPUT_WORDS (MAX_INPUT_WORDS + 1)
#define MAX_OUTPUT_BYTES (4 * MAX_INPUT_WORDS)

typedef struct {
    int length;
    uint8_t bytes[MAX_STRING_LENGTH];
} StringRecord;

static int char_at(const StringRecord *value, int depth) {
    return depth < value->length ? value->bytes[depth] : 0;
}

static int median3(int a, int b, int c) {
    if (a < b) return b < c ? b : (a < c ? c : a);
    return b > c ? b : (a < c ? a : c);
}

static int compare_from_depth(const StringRecord *left, const StringRecord *right, int depth) {
    while (depth < left->length && depth < right->length && left->bytes[depth] == right->bytes[depth]) ++depth;
    const int a = char_at(left, depth), b = char_at(right, depth);
    return (a > b) - (a < b);
}

static void insertion_sort(StringRecord *values, int lo, int hi, int depth) {
    for (int i = lo + 1; i < hi; ++i) {
        StringRecord value = values[i];
        int j = i;
        while (j > lo && compare_from_depth(&values[j - 1], &value, depth) > 0) {
            values[j] = values[j - 1];
            --j;
        }
        values[j] = value;
    }
}

static void multikey_sort(StringRecord *values, int lo, int hi, int depth) {
    const int count = hi - lo;
    if (count < 10) {
        insertion_sort(values, lo, hi, depth);
        return;
    }
    const int mid = lo + count / 2;
    int pivot;
    if (count > 30) {
        const int delta = count / 8;
        pivot = median3(median3(char_at(&values[lo], depth), char_at(&values[lo + delta], depth), char_at(&values[lo + 2 * delta], depth)),
                        median3(char_at(&values[mid - delta], depth), char_at(&values[mid], depth), char_at(&values[mid + delta], depth)),
                        median3(char_at(&values[hi - 1 - 2 * delta], depth), char_at(&values[hi - 1 - delta], depth), char_at(&values[hi - 1], depth)));
    } else {
        pivot = median3(char_at(&values[lo], depth), char_at(&values[mid], depth), char_at(&values[hi - 1], depth));
    }
    int less = lo, scan = lo, greater = hi;
    while (scan < greater) {
        const int key = char_at(&values[scan], depth);
        if (key < pivot) {
            StringRecord tmp = values[less]; values[less++] = values[scan]; values[scan++] = tmp;
        } else if (key > pivot) {
            StringRecord tmp = values[--greater]; values[greater] = values[scan]; values[scan] = tmp;
        } else {
            ++scan;
        }
    }
    multikey_sort(values, lo, less, depth);
    if (pivot != 0) multikey_sort(values, less, greater, depth + 1);
    multikey_sort(values, greater, hi, depth);
}

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t multikey_quick_sort(const int32_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_WORDS) return -1;
    const int32_t count = input[0];
    if (count < 0 || count > MAX_STRINGS) return -1;
    StringRecord values[MAX_STRINGS] = {0};
    size_t pos = 1;
    for (int32_t i = 0; i < count; ++i) {
        if (pos >= length || input[pos] < 0 || input[pos] > MAX_STRING_LENGTH) return -1;
        const int32_t string_length = input[pos++];
        if (string_length > 0 && pos + (size_t)string_length > length) return -1;
        values[i].length = (int)string_length;
        for (int32_t j = 0; j < string_length; ++j) {
            const int32_t byte = input[pos++];
            if (byte < 1 || byte > 127) return -1;
            values[i].bytes[j] = (uint8_t)byte;
        }
    }
    if (pos != length) return -1;
    const size_t word_count = length;
    const size_t bytes = word_count * 4;
    if (output == NULL || capacity < bytes) return -2;
    multikey_sort(values, 0, (int)count, 0);
    uint8_t buffer[MAX_OUTPUT_BYTES];
    size_t word = 0;
    put_i32_le(buffer, word++ * 4, count);
    for (int32_t i = 0; i < count; ++i) {
        put_i32_le(buffer, word++ * 4, values[i].length);
        for (int j = 0; j < values[i].length; ++j) put_i32_le(buffer, word++ * 4, values[i].bytes[j]);
    }
    for (size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return (int64_t)bytes;
}
