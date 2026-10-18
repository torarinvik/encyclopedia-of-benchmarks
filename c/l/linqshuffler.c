/* Replay LINQ random-key sorting with the pinned .NET seeded Random sequence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_PARSEABLE_INPUT_LENGTH 67
#define MAX_OUTPUT_BYTES 520
#define I32_MIN INT64_C(-2147483648)
#define I32_MAX INT64_C(2147483647)
#define MBIG INT64_C(2147483647)

static int64_t compat_next(int64_t seed_array[56], size_t *inext, size_t *inextp)
{
    if (++(*inext) >= 56) *inext = 1;
    if (++(*inextp) >= 56) *inextp = 1;

    int64_t sample = seed_array[*inext] - seed_array[*inextp];
    if (sample == MBIG) --sample;
    if (sample < 0) sample += MBIG;
    seed_array[*inext] = sample;
    return sample;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t linqshuffler(const int64_t *input, size_t input_length,
                     uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t seed = input[1];
    if (n_value < 0 || n_value > MAX_N || seed < I32_MIN || seed > I32_MAX) return -1;
    const size_t n = (size_t)n_value;
    if (input_length != n + 2) return -1;

    int64_t values[MAX_N] = {0};
    int64_t keys[MAX_N] = {0};
    for (size_t index = 0; index < n; ++index) {
        const int64_t value = input[index + 2];
        if (value < I32_MIN || value > I32_MAX) return -1;
        values[index] = value;
    }

    const int64_t subtraction = seed == I32_MIN ? I32_MAX : (seed < 0 ? -seed : seed);
    int64_t seed_array[56] = {0};
    int64_t mj = INT64_C(161803398) - subtraction;
    seed_array[55] = mj;
    int64_t mk = 1;
    for (size_t i = 1; i < 55; ++i) {
        const size_t ii = (21 * i) % 55;
        seed_array[ii] = mk;
        mk = mj - mk;
        if (mk < 0) mk += MBIG;
        mj = seed_array[ii];
    }
    for (size_t pass = 0; pass < 4; ++pass) {
        for (size_t i = 1; i < 56; ++i) {
            const size_t offset_index = 1 + (i + 30) % 55;
            seed_array[i] -= seed_array[offset_index];
            if (seed_array[i] < 0) seed_array[i] += MBIG;
        }
    }

    size_t inext = 0;
    size_t inextp = 21;
    for (size_t index = 0; index < n; ++index)
        keys[index] = compat_next(seed_array, &inext, &inextp);

    /* Strict comparison preserves original order for equal random keys. */
    for (size_t index = 1; index < n; ++index) {
        const int64_t key = keys[index];
        const int64_t value = values[index];
        size_t cursor = index;
        while (cursor > 0 && keys[cursor - 1] > key) {
            keys[cursor] = keys[cursor - 1];
            values[cursor] = values[cursor - 1];
            --cursor;
        }
        keys[cursor] = key;
        values[cursor] = value;
    }

    const size_t output_bytes = 8 * (n + 1);
    if (output_bytes > MAX_OUTPUT_BYTES || output == NULL || output_capacity < output_bytes) return -2;
    store_i64_le(output, 0, n_value);
    for (size_t index = 0; index < n; ++index)
        store_i64_le(output, 8 * (index + 1), values[index]);
    return (int64_t)output_bytes;
}
