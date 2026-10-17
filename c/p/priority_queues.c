#include <stddef.h>
#include <stdint.h>

#define MAX_CAPACITY 128
#define MAX_OPERATIONS 256
#define MAX_INPUT_VALUES 515
#define MAX_OUTPUT_BYTES 4096

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t priority_queues(const int64_t *input, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > MAX_CAPACITY ||
        input[1] < 0 || input[1] > MAX_OPERATIONS) return -1;

    const size_t capacity = (size_t)input[0];
    const size_t operation_count = (size_t)input[1];
    if (length != 2 + 2 * operation_count) return -1;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = input[2 + 2 * operation];
        const int64_t argument = input[3 + 2 * operation];
        if (opcode < 0 || opcode > 5) return -1;
        if (opcode == 0) {
            if (argument < INT32_MIN || argument > INT32_MAX) return -1;
        } else if (argument != 0) {
            return -1;
        }
    }

    if (operation_count == 0) return 0;
    const size_t needed = operation_count * 16;
    if (needed > MAX_OUTPUT_BYTES || output == NULL || output_capacity < needed) return -2;

    int32_t heap[MAX_CAPACITY + 1] = {0};
    size_t size = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = input[2 + 2 * operation];
        const int64_t argument = input[3 + 2 * operation];
        int64_t status = 0;
        int64_t value = 0;

        if (opcode == 0) {
            if (size == capacity) {
                status = 1;
            } else {
                heap[++size] = (int32_t)argument;
                size_t index = size;
                while (index > 1 && heap[index / 2] < heap[index]) {
                    const int32_t temporary = heap[index / 2];
                    heap[index / 2] = heap[index];
                    heap[index] = temporary;
                    index /= 2;
                }
            }
        } else if (opcode == 1) {
            if (size == 0) {
                status = 2;
            } else {
                value = heap[1];
                heap[1] = heap[size];
                heap[size] = 0;
                --size;
                size_t index = 1;
                while (index * 2 <= size) {
                    size_t child = index * 2;
                    if (child < size && heap[child + 1] > heap[child]) ++child;
                    if (heap[index] >= heap[child]) break;
                    const int32_t temporary = heap[index];
                    heap[index] = heap[child];
                    heap[child] = temporary;
                    index = child;
                }
            }
        } else if (opcode == 2) {
            value = size == 0 ? 0 : heap[1];
        } else if (opcode == 3) {
            value = size == 0 ? 1 : 0;
        } else if (opcode == 4) {
            value = size == capacity ? 1 : 0;
        } else {
            value = (int64_t)size;
        }

        store_i64_le(output, operation * 16, status);
        store_i64_le(output, operation * 16 + 8, value);
    }
    return (int64_t)needed;
}
