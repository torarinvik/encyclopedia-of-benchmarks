/* Bounded Flash Sort followed by the source's insertion-sort finishing pass. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define MAX_INPUT_LENGTH 65
#define MAX_VALUE INT64_C(1000000)

static int valid_length(size_t length) {
    return length <= 1 || (length >= 3 && length <= MAX_LENGTH);
}

static size_t class_of(int64_t value, int64_t minimum, int64_t range, size_t classes) {
    return (size_t)(((int64_t)(classes - 1) * (value - minimum)) / range);
}

static int flash_sort_values(int64_t *values, size_t length) {
    if (length <= 1) return 1;
    int64_t minimum = values[0], maximum = values[0];
    for (size_t i = 1; i < length; ++i) {
        if (values[i] < minimum) minimum = values[i];
        if (values[i] > maximum) maximum = values[i];
    }
    if (minimum == maximum) return 1;

    const int64_t range = maximum - minimum;
    size_t classes = (9 * length) / 20;
    if (classes < 1) classes = 1;
    size_t class_ends[MAX_LENGTH] = {0};
    for (size_t i = 0; i < length; ++i) ++class_ends[class_of(values[i], minimum, range, classes)];
    for (size_t i = 1; i < classes; ++i) class_ends[i] += class_ends[i - 1];

    size_t moves = 0, j = 0, k = classes - 1;
    while (moves < length - 1) {
        while (j > class_ends[k] - 1) {
            ++j;
            if (j >= length) return 0;
            k = class_of(values[j], minimum, range, classes);
        }
        int64_t flash = values[j];
        while (j != class_ends[k]) {
            k = class_of(flash, minimum, range, classes);
            size_t target = --class_ends[k];
            int64_t hold = values[target];
            values[target] = flash;
            flash = hold;
            ++moves;
        }
    }
    for (size_t i = 1; i < length; ++i) {
        int64_t key = values[i];
        size_t cursor = i;
        while (cursor > 0 && values[cursor - 1] > key) {
            values[cursor] = values[cursor - 1];
            --cursor;
        }
        values[cursor] = key;
    }
    return 1;
}

int64_t flash_sort(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (length > MAX_INPUT_LENGTH || !valid_length(length) || (length != 0 && input == NULL)) return -1;
    int64_t values[MAX_LENGTH] = {0};
    for (size_t i = 0; i < length; ++i) {
        if (input[i] < -MAX_VALUE || input[i] > MAX_VALUE) return -1;
        values[i] = input[i];
    }
    const size_t output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;
    if (!flash_sort_values(values, length)) return -1;
    for (size_t i = 0; i < length; ++i) {
        uint32_t bits = (uint32_t)(int32_t)values[i];
        for (size_t byte = 0; byte < 4; ++byte) output[i * 4 + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)output_bytes;
}
