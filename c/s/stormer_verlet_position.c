#include <stddef.h>
#include <stdint.h>

#define MAX_STEPS 32
#define MAX_INPUT_VALUES (MAX_STEPS + 1)
#define MAX_OUTPUT_BYTES (MAX_STEPS * 8)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t stormer_verlet_position(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_VALUES) return -1;
    const int64_t count_value = input[0];
    if (count_value < 2 || count_value > MAX_STEPS) return -1;
    if (length != (size_t)count_value + 1) return -1;
    if (input[1] < -1024 || input[1] > 1024 || input[2] < -1024 || input[2] > 1024)
        return -1;
    const size_t count = (size_t)count_value;
    for (size_t step = 0; step < count - 2; ++step)
        if (input[3 + step] < -64 || input[3 + step] > 64) return -1;

    const size_t byte_count = 8 * count;
    if (output == NULL || output_capacity < byte_count) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES];
    int64_t previous = input[1];
    int64_t current = input[2];
    store_i64_le(staged, 0, previous);
    store_i64_le(staged, 8, current);
    for (size_t index = 2; index < count; ++index) {
        const int64_t next = 2 * current - previous + input[index + 1];
        store_i64_le(staged, 8 * index, next);
        previous = current;
        current = next;
    }
    for (size_t byte = 0; byte < byte_count; ++byte) output[byte] = staged[byte];
    return (int64_t)byte_count;
}
