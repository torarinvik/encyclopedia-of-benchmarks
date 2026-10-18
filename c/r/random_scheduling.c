#include <stddef.h>
#include <stdint.h>

enum { MAX_TASK_COUNT = 32, MAX_INPUT_LENGTH = 35, MAX_OUTPUT_BYTES = 256 };

#define JAVA_MULTIPLIER UINT64_C(0x5DEECE66D)
#define JAVA_ADDEND UINT64_C(0xB)
#define JAVA_MASK UINT64_C(0xFFFFFFFFFFFF)

typedef struct { uint64_t state; } JavaRandom;

static uint32_t java_next_bits(JavaRandom *random, unsigned int bits)
{
    random->state = (random->state * JAVA_MULTIPLIER + JAVA_ADDEND) & JAVA_MASK;
    return (uint32_t)(random->state >> (48u - bits));
}

static uint32_t java_next_int(JavaRandom *random, uint32_t bound)
{
    if ((bound & (bound - 1u)) == 0u)
        return (uint32_t)(((uint64_t)bound * java_next_bits(random, 31u)) >> 31u);
    for (;;) {
        const uint32_t bits = java_next_bits(random, 31u);
        const uint32_t value = bits % bound;
        if ((uint64_t)bits - value + (bound - 1u) <= INT32_MAX) return value;
    }
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (unsigned int byte = 0; byte < 8u; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(0xff));
        bits >>= 8u;
    }
}

int64_t random_scheduling(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_count = input[1];
    if (raw_count < 0 || raw_count > MAX_TASK_COUNT || length != 2u + (size_t)raw_count) return -1;
    const size_t count = (size_t)raw_count;
    int64_t tasks[MAX_TASK_COUNT] = {0};
    for (size_t index = 0; index < count; ++index) {
        const int64_t task = input[index + 2u];
        if (task < INT32_MIN || task > INT32_MAX) return -1;
        tasks[index] = task;
    }

    JavaRandom random = { ((uint64_t)input[0] ^ JAVA_MULTIPLIER) & JAVA_MASK };
    for (size_t size = count; size > 1u; --size) {
        const size_t selected = java_next_int(&random, (uint32_t)size);
        const int64_t saved = tasks[size - 1u];
        tasks[size - 1u] = tasks[selected];
        tasks[selected] = saved;
    }

    const size_t output_bytes = count * 8u;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index < count; ++index)
        write_i64_le(output, index * 8u, tasks[index]);
    return (int64_t)output_bytes;
}
