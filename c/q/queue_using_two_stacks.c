/* Amortized FIFO queue implemented with an input and an output stack. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-1)
#define CAPACITY 256
#define VALUE_OFFSET INT64_C(1000000)

int64_t queue_using_two_stacks_benchmark(const int64_t *values, size_t length)
{
    if (length > 1024 || length % 2 != 0) return INVALID_RESULT;
    const size_t operation_count = length / 2;
    int64_t in_stack[CAPACITY], out_stack[CAPACITY];
    size_t in_count = 0, out_count = 0;
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = values[2 * operation], payload = values[2 * operation + 1];
        int64_t observed = 0;
        int returns_value = 1;
        if (opcode == 0) {
            if (payload < -VALUE_OFFSET || payload > VALUE_OFFSET || in_count + out_count == CAPACITY) return INVALID_RESULT;
            in_stack[in_count++] = payload;
            returns_value = 0;
        } else if (opcode == 1 || opcode == 2) {
            if (payload != 0) return INVALID_RESULT;
            if (out_count == 0) {
                while (in_count > 0) out_stack[out_count++] = in_stack[--in_count];
            }
            if (out_count == 0) return INVALID_RESULT;
            if (opcode == 1) observed = out_stack[--out_count];
            else observed = out_stack[out_count - 1];
        } else if (opcode == 3) {
            if (payload != 0) return INVALID_RESULT;
            observed = (in_count + out_count == 0);
        } else if (opcode == 4) {
            if (payload != 0) return INVALID_RESULT;
            observed = (int64_t)(in_count + out_count);
        } else return INVALID_RESULT;
        if (returns_value) checksum += ((int64_t)operation + 1) * (observed + VALUE_OFFSET);
    }
    size_t index = 0;
    while (index < out_count) {
        checksum += ((int64_t)operation_count + (int64_t)index + 1)
            * (out_stack[out_count - index - 1] + VALUE_OFFSET);
        ++index;
    }
    index = 0;
    while (index < in_count) {
        checksum += ((int64_t)operation_count + (int64_t)out_count + (int64_t)index + 1)
            * (in_stack[index] + VALUE_OFFSET);
        ++index;
    }
    return checksum;
}
