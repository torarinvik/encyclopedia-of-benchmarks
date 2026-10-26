#include <stddef.h>
#include <stdint.h>

enum { SCALE = 16, MAX_N = 12, MAX_STEPS = 64, MAX_INPUT = 79, MAX_OUTPUT = 208 };
static void put_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) { out[offset + b] = (uint8_t)(bits & 255); bits >>= 8; }
}

int64_t ring_exact_covering_protocol(const int64_t *v, size_t length, uint8_t *output, size_t capacity) {
    if (v == NULL || length < 3 || length > MAX_INPUT || v[0] < 2 || v[0] > MAX_N) return -1;
    const size_t n = (size_t)v[0];
    const int64_t visibility = v[1], steps64 = v[2];
    if (steps64 < 0 || steps64 > MAX_STEPS || length != 3 + n + (size_t)steps64) return -1;
    const size_t steps = (size_t)steps64;
    const int64_t circumference = SCALE * (int64_t)n;
    if (visibility < 2 * SCALE || visibility > circumference) return -1;
    int64_t position[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        position[i] = v[3 + i];
        if (position[i] < 0 || position[i] >= circumference) return -1;
        if (i > 0 && position[i - 1] >= position[i]) return -1;
    }
    for (size_t step = 0; step < steps; ++step)
        if (v[3 + n + step] < 0 || v[3 + n + step] >= (int64_t)n) return -1;

    int64_t moved = 0;
    for (size_t step = 0; step < steps; ++step) {
        const size_t sensor = (size_t)v[3 + n + step], successor = (sensor + 1) % n;
        const int64_t gap = (position[successor] - position[sensor] + circumference) % circumference;
        const int64_t distance = gap > visibility ? SCALE : (gap > SCALE ? gap - SCALE : 0);
        if (distance != 0) { position[sensor] = (position[sensor] + distance) % circumference; ++moved; }
    }
    const size_t words = 2 + 2 * n, bytes = 8 * words;
    if (output == NULL || capacity < bytes) return -2;
    int64_t staged_words[2 + 2 * MAX_N];
    staged_words[0] = (int64_t)n; staged_words[1] = moved;
    for (size_t i = 0; i < n; ++i) staged_words[2 + i] = position[i];
    for (size_t i = 0; i < n; ++i)
        staged_words[2 + n + i] = (position[(i + 1) % n] - position[i] + circumference) % circumference;
    uint8_t staged[MAX_OUTPUT];
    for (size_t i = 0; i < words; ++i) put_i64(staged, 8 * i, staged_words[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
