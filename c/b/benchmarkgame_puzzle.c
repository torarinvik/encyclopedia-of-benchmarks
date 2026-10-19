#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MAX_ARRAY_SIZE 100000
#define MAX_ROUNDS 8
#define MAX_SCANS_PER_ARRAY 64

static uint32_t puzzle_rand(uint64_t *state) {
    *state = *state * UINT64_C(1103515245) + UINT64_C(12345);
    const uint32_t shifted = (uint32_t)(*state / UINT64_C(65536));
    return shifted % UINT32_C(32767) + UINT32_C(1);
}

static size_t puzzle_rand_int(size_t minimum, size_t maximum, uint64_t *state) {
    const size_t range = maximum - minimum + 1;
    const uint32_t draw = puzzle_rand(state);
    const size_t offset = (size_t)((double)range * ((double)draw / 32768.0));
    return offset == range ? offset + minimum - 1 : offset + minimum;
}

static void puzzle_shuffle(int32_t *items, size_t length, uint64_t *state) {
    for (size_t index = length - 1; index > 0; --index) {
        const size_t range = index + 1;
        const uint32_t draw = puzzle_rand(state);
        const size_t k = (size_t)((double)range * ((double)draw / 32768.0));
        const size_t chosen = k == range ? k - 1 : k;
        const int32_t temporary = items[index];
        items[index] = items[chosen];
        items[chosen] = temporary;
    }
}

static int32_t puzzle_find_duplicate(const int32_t *data, size_t length) {
    uint32_t result = 0;
    for (size_t index = 0; index < length; ++index)
        result ^= (uint32_t)(index + 1) ^ (uint32_t)data[index];
    result ^= (uint32_t)length;
    return (int32_t)result;
}

static void puzzle_store_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t benchmarkgame_puzzle(const int64_t *input, size_t length,
                             uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 3) return -1;
    const int64_t raw_size = input[0], raw_rounds = input[1], raw_scans = input[2];
    if (raw_size < 1 || raw_size > MAX_ARRAY_SIZE || raw_rounds < 1 || raw_rounds > MAX_ROUNDS ||
        raw_scans < 1 || raw_scans > MAX_SCANS_PER_ARRAY) return -1;
    const size_t size = (size_t)raw_size;
    const size_t rounds = (size_t)raw_rounds;
    const size_t scans = (size_t)raw_scans;
    const size_t output_bytes = rounds * 4;
    if (output_capacity < output_bytes || output == NULL) return -2;

    uint64_t random_state = 1;
    for (size_t round = 0; round < rounds; ++round) {
        int32_t *data = (int32_t *)malloc((size + 1) * sizeof(*data));
        if (data == NULL) return -1;
        for (size_t index = 0; index <= size; ++index) data[index] = (int32_t)index;
        data[0] = (int32_t)puzzle_rand_int(1, size, &random_state);
        puzzle_shuffle(data, size + 1, &random_state);
        int32_t duplicate = 0;
        for (size_t scan = 0; scan < scans; ++scan)
            duplicate = puzzle_find_duplicate(data, size + 1);
        puzzle_store_i32_le(output, round * 4, duplicate);
        free(data);
    }
    return (int64_t)output_bytes;
}
