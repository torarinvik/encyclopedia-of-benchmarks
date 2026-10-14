/* Bounded array-backed integer stack used by the shared operation-trace benchmark. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-1)
#define CAPACITY 256
#define MAX_OPERATIONS 512
#define VALUE_OFFSET INT64_C(1000000)

int64_t stack_benchmark(const int64_t *values, size_t length)
{
    if (length > 2 * MAX_OPERATIONS || length % 2 != 0) return INVALID_RESULT;
    const size_t operation_count = length / 2;
    int64_t data_stack[CAPACITY];
    size_t top = 0;
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = values[2 * operation];
        const int64_t payload = values[2 * operation + 1];
        int64_t observed = 0;
        int returns_value = 1;
        if (opcode == 0) {
            if (payload < -VALUE_OFFSET || payload > VALUE_OFFSET || top == CAPACITY) return INVALID_RESULT;
            data_stack[top++] = payload;
            returns_value = 0;
        } else if (opcode == 1) {
            if (payload != 0 || top == 0) return INVALID_RESULT;
            observed = data_stack[--top];
        } else if (opcode == 2) {
            if (payload != 0 || top == 0) return INVALID_RESULT;
            observed = data_stack[top - 1];
        } else if (opcode == 3) {
            if (payload != 0) return INVALID_RESULT;
            observed = top == 0 ? 1 : 0;
        } else return INVALID_RESULT;
        if (returns_value) checksum += ((int64_t)operation + 1) * (observed + VALUE_OFFSET);
    }
    for (size_t index = 0; index < top; ++index) {
        checksum += ((int64_t)operation_count + (int64_t)index + 1) * (data_stack[index] + VALUE_OFFSET);
    }
    return checksum;
}
