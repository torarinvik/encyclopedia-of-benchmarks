/* Bounded circular buffer that overwrites the oldest item when full. */
#include <stddef.h>
#include <stdint.h>

#define MAX_CAPACITY 256
#define MAX_OPERATIONS 512
#define VALUE_OFFSET INT64_C(1000000)

int64_t circular_buffer_benchmark(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > 1 + 2 * MAX_OPERATIONS || (length - 1) % 2 != 0) return -1;
    if (values[0] < 1 || values[0] > MAX_CAPACITY) return -1;
    const size_t capacity = (size_t)values[0];
    const size_t operation_count = (length - 1) / 2;
    int64_t buffer[MAX_CAPACITY];
    size_t head = 0, tail = 0, count = 0;
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = values[1 + 2 * operation];
        const int64_t payload = values[2 + 2 * operation];
        int64_t observed = 0;
        if (opcode == 0) {
            if (payload < 0 || payload > VALUE_OFFSET) return -1;
            const int was_empty = count == 0;
            if (count == capacity) head = (head + 1) % capacity;
            else ++count;
            buffer[tail] = payload;
            tail = (tail + 1) % capacity;
            observed = was_empty;
        } else if (opcode == 1) {
            if (payload != 0) return -1;
            if (count == 0) observed = -1;
            else {
                observed = buffer[head];
                head = (head + 1) % capacity;
                --count;
            }
        } else if (opcode == 2) {
            if (payload != 0) return -1;
            observed = count == 0;
        } else if (opcode == 3) {
            if (payload != 0) return -1;
            observed = count == capacity;
        } else if (opcode == 4) {
            if (payload != 0) return -1;
            observed = (int64_t)count;
        } else return -1;
        checksum += ((int64_t)operation + 1) * (observed + VALUE_OFFSET);
    }
    for (size_t index = 0; index < count; ++index)
        checksum += ((int64_t)operation_count + (int64_t)index + 1) * (buffer[(head + index) % capacity] + VALUE_OFFSET);
    return checksum;
}
