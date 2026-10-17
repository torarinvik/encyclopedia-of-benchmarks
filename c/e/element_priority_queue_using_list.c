#include <stddef.h>
#include <stdint.h>

static void store_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t element_priority_queue_using_list(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 514) return -1;
    const int64_t op_count = input[0];
    if (op_count < 0 || op_count > 256 || length != 1 + 2 * (size_t)op_count) return -1;
    int32_t queue[100];
    size_t queue_count = 0;
    int64_t dequeued[128];
    size_t dequeued_count = 0;
    for (size_t i = 0; i < (size_t)op_count; ++i) {
        const int64_t opcode = input[1 + 2 * i], argument = input[2 + 2 * i];
        if (opcode == 0) {
            if (argument < INT32_MIN || argument > INT32_MAX || queue_count == 100) return -1;
            queue[queue_count++] = (int32_t)argument;
        } else if (opcode == 1) {
            if (argument != 0 || queue_count == 0) return -1;
            size_t minimum = 0;
            for (size_t j = 1; j < queue_count; ++j) if (queue[j] < queue[minimum]) minimum = j;
            dequeued[dequeued_count++] = queue[minimum];
            --queue_count;
            for (size_t j = minimum; j < queue_count; ++j) queue[j] = queue[j + 1];
        } else return -1;
    }
    const size_t output_bytes = dequeued_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < dequeued_count; ++i) store_i64(output, i * 8, dequeued[i]);
    return (int64_t)output_bytes;
}
