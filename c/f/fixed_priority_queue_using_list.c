#include <stddef.h>
#include <stdint.h>

static void store_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t fixed_priority_queue_using_list(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 770) return -1;
    const int64_t op_count = input[0];
    if (op_count < 0 || op_count > 256 || length != 1 + 3 * (size_t)op_count) return -1;
    int32_t buckets[3][100];
    size_t counts[3] = {0, 0, 0};
    int64_t dequeued[128];
    size_t dequeued_count = 0;
    for (size_t i = 0; i < (size_t)op_count; ++i) {
        const int64_t opcode = input[1 + 3 * i], priority = input[2 + 3 * i], data = input[3 + 3 * i];
        if (opcode == 0) {
            if (priority < -3 || priority > 2 || data < INT32_MIN || data > INT32_MAX) return -1;
            const size_t bucket = (size_t)(priority < 0 ? priority + 3 : priority);
            if (counts[bucket] == 100) return -1;
            buckets[bucket][counts[bucket]++] = (int32_t)data;
        } else if (opcode == 1) {
            if (priority != 0 || data != 0) return -1;
            size_t bucket = 0;
            while (bucket < 3 && counts[bucket] == 0) ++bucket;
            if (bucket == 3) return -1;
            dequeued[dequeued_count++] = buckets[bucket][0];
            --counts[bucket];
            for (size_t j = 0; j < counts[bucket]; ++j) buckets[bucket][j] = buckets[bucket][j + 1];
        } else return -1;
    }
    const size_t output_bytes = dequeued_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < dequeued_count; ++i) store_i64(output, i * 8, dequeued[i]);
    return (int64_t)output_bytes;
}
