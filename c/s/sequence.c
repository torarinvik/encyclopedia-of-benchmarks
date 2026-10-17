#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 64
#define MAX_PARSEABLE_INPUT_LENGTH 3
#define MAX_OUTPUT_BYTES (8 * MAX_COUNT)

static int64_t generate_nth_term(int64_t index)
{
    if (index == 0 || index == 1) return index;
    if (index % 2 == 0) return 4 * generate_nth_term(index / 2);
    return 4 * generate_nth_term(index / 2) + 1;
}

static void put_i64_le(int64_t value, uint8_t *output, size_t offset)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t sequence(const int64_t *values, size_t length,
                 uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (length != 1 || values[0] < -MAX_COUNT || values[0] > MAX_COUNT) return -1;
    if (values[0] <= 0) return 0;

    const size_t count = (size_t)values[0];
    const size_t required = count * 8;
    if (output == NULL || output_capacity < required || required > MAX_OUTPUT_BYTES) return -2;
    for (size_t index = 0; index < count; ++index)
        put_i64_le(generate_nth_term((int64_t)index), output, index * 8);
    return (int64_t)required;
}
