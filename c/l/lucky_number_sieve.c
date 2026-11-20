#include <stddef.h>
#include <stdint.h>

#define MAX_CANDIDATES 2048
#define MAX_BOUND 4096

int64_t lucky_number_sieve(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 2) return -1;
    const int64_t mode = input[0];
    const int64_t bound = input[1];
    if ((mode != 0 && mode != 1) || bound < 0 || bound > MAX_BOUND) return -1;

    int64_t candidates[MAX_CANDIDATES];
    size_t count = 0;
    const int64_t first = mode == 0 ? 1 : 2;
    for (int64_t value = first; value <= bound; value += 2)
        candidates[count++] = value;

    size_t selected = 1;
    while (selected < count) {
        const size_t step = (size_t)candidates[selected];
        if (step > count) break;
        size_t write = 0;
        size_t rank = 0;
        for (size_t read = 0; read < count; ++read) {
            ++rank;
            if (rank % step != 0) candidates[write++] = candidates[read];
        }
        count = write;
        ++selected;
    }

    const size_t output_bytes = count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < count; ++index) {
        const uint64_t bits = (uint64_t)candidates[index];
        for (size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)output_bytes;
}
