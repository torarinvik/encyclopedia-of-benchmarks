#include <stddef.h>
#include <stdint.h>

enum { MAX_JOBS = 4, MAX_SAMPLES = 8, MAX_TIME = 8, MAX_OUTPUT_BYTES = 136 };
static const int64_t E_NUM = 271828, E_DEN = 100000, EM1_NUM = 171828;

static int64_t gcd64(int64_t a, int64_t b) {
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a < 0 ? -a : a;
}

static void candidate_speed(const int64_t *release, const int64_t *deadline,
    const int64_t *work, size_t n, int64_t time, int64_t endpoint_num,
    int64_t endpoint_den, int64_t *best_num, int64_t *best_den) {
    int64_t delta = endpoint_num - time * endpoint_den;
    if (delta <= 0) return;
    int64_t left_scaled = E_NUM * time * endpoint_den - EM1_NUM * endpoint_num;
    int64_t window_work = 0;
    for (size_t j = 0; j < n; ++j) {
        if (release[j] <= time &&
            left_scaled <= E_DEN * endpoint_den * release[j] &&
            deadline[j] * endpoint_den <= endpoint_num) window_work += work[j];
    }
    int64_t numerator = window_work * endpoint_den;
    if (numerator * *best_den > *best_num * delta) {
        *best_num = numerator;
        *best_den = delta;
    }
}

static void write64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) output[offset + b] = (uint8_t)(bits >> (8 * b));
}

int64_t bkp_speed_scaling_trace(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 31) return -1;
    int64_t n64 = input[0], samples64 = input[1];
    if (n64 < 1 || n64 > MAX_JOBS || samples64 < 1 || samples64 > MAX_SAMPLES) return -1;
    size_t n = (size_t)n64, samples = (size_t)samples64;
    if (length != 2 + 3 * n + 2 * samples) return -1;
    int64_t release[MAX_JOBS], deadline[MAX_JOBS], work[MAX_JOBS];
    for (size_t j = 0; j < n; ++j) {
        release[j] = input[2 + 3 * j]; deadline[j] = input[3 + 3 * j]; work[j] = input[4 + 3 * j];
        if (release[j] < 0 || release[j] >= deadline[j] || deadline[j] > MAX_TIME ||
            work[j] < 1 || work[j] > 8) return -1;
    }
    int64_t values[1 + 2 * MAX_SAMPLES];
    values[0] = samples64;
    size_t sample_offset = 2 + 3 * n;
    for (size_t s = 0; s < samples; ++s) {
        int64_t time = input[sample_offset + 2 * s];
        int64_t mask = input[sample_offset + 2 * s + 1];
        if (time < 0 || time > MAX_TIME || mask < 0 || mask >= (INT64_C(1) << n)) return -1;
        for (size_t j = 0; j < n; ++j)
            if ((mask & (INT64_C(1) << j)) != 0 && release[j] > time) return -1;
        int64_t best_num = 0, best_den = 1;
        if (mask != 0) for (size_t j = 0; j < n; ++j) if (release[j] <= time) {
            if (deadline[j] > time) candidate_speed(release, deadline, work, n, time,
                deadline[j], 1, &best_num, &best_den);
            if (release[j] < time) candidate_speed(release, deadline, work, n, time,
                E_NUM * time - E_DEN * release[j], EM1_NUM, &best_num, &best_den);
        }
        int64_t divisor = gcd64(best_num, best_den);
        values[1 + 2 * s] = best_num / divisor;
        values[2 + 2 * s] = best_den / divisor;
    }
    size_t bytes = 8 * (1 + 2 * samples);
    if (output == NULL || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t i = 0; i < 1 + 2 * samples; ++i) write64(staged, 8 * i, values[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
