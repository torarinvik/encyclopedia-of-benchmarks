#include <stddef.h>
#include <stdint.h>

#define MAX_JOBS 32
#define MAX_ARRIVAL 64
#define MAX_BURST 128
#define SENTINEL INT64_C(999999999)

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t shortest_job_first(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > MAX_JOBS || length != 1 + 2 * (size_t)raw_count) return -1;
    const size_t count = (size_t)raw_count;
    int64_t remaining[MAX_JOBS] = {0};
    int64_t waiting[MAX_JOBS] = {0};
    for (size_t i = 0; i < count; ++i) {
        if (input[1 + i] < 0 || input[1 + i] > MAX_ARRIVAL) return -1;
        const int64_t burst = input[1 + count + i];
        if (burst < 1 || burst > MAX_BURST || burst >= SENTINEL) return -1;
        remaining[i] = burst;
    }
    const size_t bytes = (1 + 2 * count) * 8;
    if (output == NULL || capacity < bytes) return -2;
    size_t complete = 0;
    int64_t time = 0, minimum = SENTINEL;
    size_t short_index = 0;
    int check = 0;
    while (complete != count) {
        for (size_t j = 0; j < count; ++j) {
            if (input[1 + j] <= time && remaining[j] > 0 && remaining[j] < minimum) {
                minimum = remaining[j];
                short_index = j;
                check = 1;
            }
        }
        if (!check) { ++time; continue; }
        --remaining[short_index];
        minimum = remaining[short_index];
        if (minimum == 0) minimum = SENTINEL;
        if (remaining[short_index] == 0) {
            ++complete;
            check = 0;
            const int64_t finish_time = time + 1;
            const int64_t wait = finish_time - input[1 + short_index] - input[1 + count + short_index];
            waiting[short_index] = wait > 0 ? wait : 0;
        }
        ++time;
    }
    put_i64_le(output, 0, raw_count);
    for (size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (1 + i), waiting[i]);
    for (size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (1 + count + i), input[1 + count + i] + waiting[i]);
    return (int64_t)bytes;
}
