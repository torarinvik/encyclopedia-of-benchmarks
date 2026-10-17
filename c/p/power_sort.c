#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 64
#define MAX_INPUT_VALUES 67
#define MIN_VALUE INT64_C(-1000000)
#define MAX_VALUE INT64_C(1000000)

typedef struct {
    size_t start;
    size_t length;
    int64_t power;
} run_entry;

static int key_less(int64_t left, int64_t right, int reverse) {
    return reverse ? left > right : left < right;
}

static size_t find_run(int64_t *values, size_t start, size_t end, int reverse) {
    if (start >= end - 1) return start + 1;
    size_t run_end = start + 1;
    if (key_less(values[run_end], values[start], reverse)) {
        while (run_end < end && key_less(values[run_end], values[run_end - 1], reverse)) ++run_end;
        for (size_t left = start, right = run_end - 1; left < right; ++left, --right) {
            const int64_t temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
        }
    } else {
        while (run_end < end && !key_less(values[run_end], values[run_end - 1], reverse)) ++run_end;
    }
    return run_end;
}

static int64_t node_power(size_t total_length, size_t b1, size_t n1, size_t b2, size_t n2) {
    const int64_t a = (int64_t)(2 * b1 + n1);
    const int64_t b = (int64_t)(2 * b2 + n2);
    const int64_t denominator = (int64_t)(2 * total_length);
    int64_t power = 0;
    while ((a * (INT64_C(1) << power)) / denominator ==
           (b * (INT64_C(1) << power)) / denominator) ++power;
    return power;
}

static void merge_runs(int64_t *values, size_t start1, size_t end1, size_t end2, int reverse) {
    int64_t left[MAX_VALUES];
    int64_t right[MAX_VALUES];
    const size_t left_length = end1 - start1;
    const size_t right_length = end2 - end1;
    for (size_t index = 0; index < left_length; ++index) left[index] = values[start1 + index];
    for (size_t index = 0; index < right_length; ++index) right[index] = values[end1 + index];

    size_t i = 0, j = 0, output = start1;
    while (i < left_length && j < right_length) {
        const int take_left = reverse ? left[i] >= right[j] : left[i] <= right[j];
        values[output++] = take_left ? left[i++] : right[j++];
    }
    while (i < left_length) values[output++] = left[i++];
    while (j < right_length) values[output++] = right[j++];
}

static void power_sort(int64_t *values, size_t length, int reverse) {
    if (length <= 1) return;
    run_entry stack[MAX_VALUES];
    size_t stack_size = 0;
    size_t start = 0;

    while (start < length) {
        const size_t run_end = find_run(values, start, length, reverse);
        size_t run_length = run_end - start;
        int64_t power = stack_size == 0
            ? 0
            : node_power(length, stack[stack_size - 1].start, stack[stack_size - 1].length, start, run_length);

        while (stack_size > 0 && stack[stack_size - 1].power >= power) {
            const run_entry previous = stack[--stack_size];
            merge_runs(values, previous.start, previous.start + previous.length, run_end, reverse);
            start = previous.start;
            run_length = run_end - start;
            power = stack_size == 0
                ? 0
                : node_power(length, stack[stack_size - 1].start, stack[stack_size - 1].length, start, run_length);
        }
        stack[stack_size++] = (run_entry){start, run_length, power};
        start = run_end;
    }

    while (stack_size > 1) {
        const run_entry right = stack[--stack_size];
        const run_entry left = stack[--stack_size];
        const size_t merged_end = right.start + right.length;
        merge_runs(values, left.start, left.start + left.length, merged_end, reverse);
        const size_t merged_length = merged_end - left.start;
        const int64_t power = stack_size == 0
            ? 0
            : node_power(length, stack[stack_size - 1].start, stack[stack_size - 1].length, left.start, merged_length);
        stack[stack_size++] = (run_entry){left.start, merged_length, power};
    }
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t power_sort(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t reverse_value = input[0];
    const int64_t count_value = input[1];
    if ((reverse_value != 0 && reverse_value != 1) || count_value < 0 || count_value > MAX_VALUES) return -1;
    const size_t count = (size_t)count_value;
    if (length != 2 + count) return -1;

    int64_t values[MAX_VALUES];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[2 + index];
        if (value < MIN_VALUE || value > MAX_VALUE) return -1;
        values[index] = value;
    }
    if (count == 0) return 0;
    const size_t output_bytes = 8 * count;
    if (output == NULL || capacity < output_bytes) return -2;

    power_sort(values, count, (int)reverse_value);
    for (size_t index = 0; index < count; ++index) write_i64_le(output, 8 * index, values[index]);
    return (int64_t)output_bytes;
}
