#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 256
#define MAX_INPUT_LENGTH 514
#define MAX_LIVE_VALUES 64
#define NIL_SENTINEL INT64_MIN

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}
static void push_max(int32_t *heap, size_t *count, int32_t value) {
    size_t position = (*count)++;
    while (position > 0 && heap[(position - 1) / 2] < value) { size_t parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent; }
    heap[position] = value;
}
static int32_t pop_max(int32_t *heap, size_t *count) {
    int32_t result = heap[0], value = heap[--(*count)]; if (*count == 0) return result;
    size_t position = 0;
    while (2 * position + 1 < *count) { size_t child = 2 * position + 1; if (child + 1 < *count && heap[child + 1] > heap[child]) ++child; if (heap[child] <= value) break; heap[position] = heap[child]; position = child; }
    heap[position] = value; return result;
}
static void push_min(int32_t *heap, size_t *count, int32_t value) {
    size_t position = (*count)++;
    while (position > 0 && heap[(position - 1) / 2] > value) { size_t parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent; }
    heap[position] = value;
}
static int32_t pop_min(int32_t *heap, size_t *count) {
    int32_t result = heap[0], value = heap[--(*count)]; if (*count == 0) return result;
    size_t position = 0;
    while (2 * position + 1 < *count) { size_t child = 2 * position + 1; if (child + 1 < *count && heap[child + 1] < heap[child]) ++child; if (heap[child] >= value) break; heap[position] = heap[child]; position = child; }
    heap[position] = value; return result;
}

int64_t median_heap(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS || length != 1 + 2 * (size_t)operation_count_value) return -1;
    const size_t operation_count = (size_t)operation_count_value;
    int32_t lower[MAX_LIVE_VALUES], upper[MAX_LIVE_VALUES]; size_t lower_count = 0, upper_count = 0;
    int64_t results[MAX_OPERATIONS];
    for (size_t i = 0; i < operation_count; ++i) {
        const int64_t opcode = input[1 + 2 * i], argument = input[2 + 2 * i];
        if (opcode == 0) {
            if (argument < INT32_MIN || argument > INT32_MAX || lower_count + upper_count >= MAX_LIVE_VALUES) return -1;
            const int32_t value = (int32_t)argument;
            if (lower_count == 0) { push_max(lower, &lower_count, value); }
            else if (value < lower[0]) {
                push_max(lower, &lower_count, value);
                if (lower_count - upper_count > 1) push_min(upper, &upper_count, pop_max(lower, &lower_count));
            } else {
                push_min(upper, &upper_count, value);
                if (lower_count < upper_count) push_max(lower, &lower_count, pop_min(upper, &upper_count));
            }
            results[i] = NIL_SENTINEL;
        } else if (opcode >= 1 && opcode <= 4) {
            if (argument != 0) return -1;
            if (opcode == 1) results[i] = lower_count ? lower[0] : NIL_SENTINEL;
            else if (opcode == 2) {
                if (lower_count == 0) results[i] = NIL_SENTINEL;
                else {
                    results[i] = pop_max(lower, &lower_count);
                    if (lower_count < upper_count) push_max(lower, &lower_count, pop_min(upper, &upper_count));
                }
            } else if (opcode == 3) results[i] = (int64_t)(lower_count + upper_count);
            else results[i] = lower_count == 0 ? 1 : 0;
        } else return -1;
    }
    const size_t output_bytes = operation_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < operation_count; ++i) store_i64_le(output, 8 * i, results[i]);
    return (int64_t)output_bytes;
}
