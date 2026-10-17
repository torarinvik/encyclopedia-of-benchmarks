#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 64
#define MAX_INPUT_LENGTH 66

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}
static void push_max(int64_t *heap, size_t *count, int64_t value) {
    size_t position = (*count)++;
    while (position > 0 && heap[(position - 1) / 2] < value) {
        size_t parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
static int64_t pop_max(int64_t *heap, size_t *count) {
    int64_t result = heap[0], value = heap[--(*count)];
    if (*count == 0) return result;
    size_t position = 0;
    while (2 * position + 1 < *count) {
        size_t child = 2 * position + 1;
        if (child + 1 < *count && heap[child + 1] > heap[child]) ++child;
        if (heap[child] <= value) break;
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; return result;
}
static void push_min(int64_t *heap, size_t *count, int64_t value) {
    size_t position = (*count)++;
    while (position > 0 && heap[(position - 1) / 2] > value) {
        size_t parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
static int64_t pop_min(int64_t *heap, size_t *count) {
    int64_t result = heap[0], value = heap[--(*count)];
    if (*count == 0) return result;
    size_t position = 0;
    while (2 * position + 1 < *count) {
        size_t child = 2 * position + 1;
        if (child + 1 < *count && heap[child + 1] < heap[child]) ++child;
        if (heap[child] >= value) break;
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; return result;
}

int64_t median_of_running_array_long(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > MAX_COUNT || length != 1 + (size_t)count_value) return -1;
    const size_t count = (size_t)count_value;
    int64_t lower[MAX_COUNT], upper[MAX_COUNT], medians[MAX_COUNT];
    size_t lower_count = 0, upper_count = 0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t sample = input[i + 1];
        if (sample < -4611686018427387904LL || sample > 4611686018427387903LL) return -1;
        if (upper_count > 0 && sample < upper[0]) push_max(lower, &lower_count, sample);
        else push_min(upper, &upper_count, sample);
        if (lower_count > upper_count + 1) push_min(upper, &upper_count, pop_max(lower, &lower_count));
        else if (upper_count > lower_count + 1) push_max(lower, &lower_count, pop_min(upper, &upper_count));
        if (lower_count > upper_count) medians[i] = lower[0];
        else if (upper_count > lower_count) medians[i] = upper[0];
        else medians[i] = (lower[0] + upper[0]) / 2;
    }
    const size_t output_bytes = count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < count; ++i) store_i64_le(output, 8 * i, medians[i]);
    return (int64_t)output_bytes;
}
