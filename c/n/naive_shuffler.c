#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 256
#define RNG_MODULUS INT64_C(2147483647)
#define RNG_PERIOD (RNG_MODULUS - 1)

int64_t naive_shuffler(const int64_t *input, size_t length, uint8_t *output,
                       size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_ITEMS + 2) return -1;
    if (input[0] < 0 || input[0] >= RNG_PERIOD || input[1] < 0 || input[1] > MAX_ITEMS) return -1;
    const size_t count = (size_t)input[1];
    if (length != count + 2) return -1;

    uint8_t items[MAX_ITEMS];
    for (size_t index = 0; index < count; ++index) {
        if (input[index + 2] < 0 || input[index + 2] > 255) return -1;
        items[index] = (uint8_t)input[index + 2];
    }
    if (output_capacity < count || (count > 0 && output == NULL)) return -2;

    int64_t state = input[0] + 1;
    for (size_t index = 0; index < count; ++index) {
        const int64_t bound = (int64_t)count;
        const int64_t limit = RNG_PERIOD - RNG_PERIOD % bound;
        int64_t sample;
        do {
            state = (state * INT64_C(48271)) % RNG_MODULUS;
            sample = state - 1;
        } while (sample >= limit);
        const size_t other = (size_t)(sample % bound);
        const uint8_t temporary = items[index];
        items[index] = items[other];
        items[other] = temporary;
    }
    for (size_t index = 0; index < count; ++index) output[index] = items[index];
    return (int64_t)count;
}
