#include <stddef.h>
#include <stdint.h>

static void push_max(int32_t *heap, size_t *count, int32_t value) {
    size_t i = (*count)++;
    while (i > 0 && heap[(i - 1) / 2] < value) { heap[i] = heap[(i - 1) / 2]; i = (i - 1) / 2; }
    heap[i] = value;
}
static int32_t pop_max(int32_t *heap, size_t *count) {
    int32_t result = heap[0], value = heap[--(*count)];
    if (*count == 0) return result;
    size_t i = 0;
    while (2 * i + 1 < *count) {
        size_t child = 2 * i + 1;
        if (child + 1 < *count && heap[child + 1] > heap[child]) ++child;
        if (heap[child] <= value) break;
        heap[i] = heap[child]; i = child;
    }
    heap[i] = value;
    return result;
}
static void push_min(int32_t *heap, size_t *count, int32_t value) {
    size_t i = (*count)++;
    while (i > 0 && heap[(i - 1) / 2] > value) { heap[i] = heap[(i - 1) / 2]; i = (i - 1) / 2; }
    heap[i] = value;
}
static int32_t pop_min(int32_t *heap, size_t *count) {
    int32_t result = heap[0], value = heap[--(*count)];
    if (*count == 0) return result;
    size_t i = 0;
    while (2 * i + 1 < *count) {
        size_t child = 2 * i + 1;
        if (child + 1 < *count && heap[child + 1] < heap[child]) ++child;
        if (heap[child] >= value) break;
        heap[i] = heap[child]; i = child;
    }
    heap[i] = value;
    return result;
}

int64_t median_of_running_array_byte(const int32_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 66) return -1;
    const int32_t count_value = input[0];
    if (count_value < 1 || count_value > 64 || length != 1 + (size_t)count_value) return -1;
    int32_t lower[64], upper[64];
    uint8_t medians[64];
    size_t lower_count = 0, upper_count = 0;
    for (size_t i = 0; i < (size_t)count_value; ++i) {
        const int32_t sample = input[i + 1];
        if (sample < -128 || sample > 127) return -1;
        if (upper_count > 0 && sample < upper[0]) push_max(lower, &lower_count, sample);
        else push_min(upper, &upper_count, sample);
        if (lower_count > upper_count + 1) push_min(upper, &upper_count, pop_max(lower, &lower_count));
        else if (upper_count > lower_count + 1) push_max(lower, &lower_count, pop_min(upper, &upper_count));
        int32_t median;
        if (lower_count > upper_count) median = lower[0];
        else if (upper_count > lower_count) median = upper[0];
        else {
            const int32_t sum = lower[0] + upper[0];
            median = sum < 0 ? -((-sum) / 2) : sum / 2;
        }
        medians[i] = (uint8_t)(int8_t)median;
    }
    if (output == NULL || capacity < (size_t)count_value) return -2;
    for (size_t i = 0; i < (size_t)count_value; ++i) output[i] = medians[i];
    return count_value;
}
