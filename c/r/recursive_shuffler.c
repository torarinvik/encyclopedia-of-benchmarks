#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 64
#define MODULUS UINT64_C(2147483647)

static void shuffle_recursive(int32_t *values, int item, uint64_t *state) {
    if (item <= 0) return;
    shuffle_recursive(values, item - 1, state);
    *state = (*state * UINT64_C(48271)) % MODULUS;
    const size_t other = (size_t)(*state % (uint64_t)(item + 1));
    const int32_t temporary = values[item];
    values[item] = values[other];
    values[other] = temporary;
}

int64_t recursive_shuffler(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_VALUES + 1) return -1;
    const int64_t seed = input[0];
    if (seed < 1 || seed >= (int64_t)MODULUS) return -1;
    const size_t count = length - 1;
    int32_t values[MAX_VALUES];
    for (size_t i = 0; i < count; ++i) {
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;
        values[i] = (int32_t)input[i + 1];
    }
    const size_t byte_count = count * 4;
    if (output_capacity < byte_count || (byte_count != 0 && output == NULL)) return -2;
    uint64_t state = (uint64_t)seed;
    if (count > 1) shuffle_recursive(values, (int)count - 1, &state);
    for (size_t i = 0; i < count; ++i) {
        const uint32_t bits = (uint32_t)values[i];
        for (size_t byte = 0; byte < 4; ++byte)
            output[i * 4 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)count;
}
