#include <stddef.h>
#include <stdint.h>

#define MAX_JOBS 32
#define MAX_BURST 4096
#define QUANTUM 2

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t round_robin(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > MAX_JOBS || length != (size_t)raw_count + 1) return -1;
    const size_t count = (size_t)raw_count;
    int64_t remaining[MAX_JOBS] = {0};
    int64_t waiting[MAX_JOBS] = {0};
    for (size_t i = 0; i < count; ++i) {
        const int64_t burst = input[i + 1];
        if (burst < 0 || burst > MAX_BURST) return -1;
        remaining[i] = burst;
    }
    const size_t bytes = (1 + 2 * count) * 8;
    if (output == NULL || capacity < bytes) return -2;
    int64_t elapsed = 0;
    for (;;) {
        int done = 1;
        for (size_t i = 0; i < count; ++i) {
            if (remaining[i] > 0) {
                done = 0;
                if (remaining[i] > QUANTUM) {
                    elapsed += QUANTUM;
                    remaining[i] -= QUANTUM;
                } else {
                    elapsed += remaining[i];
                    waiting[i] = elapsed - input[i + 1];
                    remaining[i] = 0;
                }
            }
        }
        if (done) break;
    }
    put_i64_le(output, 0, raw_count);
    for (size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (1 + i), waiting[i]);
    for (size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (1 + count + i), input[i + 1] + waiting[i]);
    return (int64_t)bytes;
}
