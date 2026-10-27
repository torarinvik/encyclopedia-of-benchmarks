#include <stddef.h>
#include <stdint.h>

enum { MAX_JOBS = 4, MAX_TIME = 8, MAX_INPUT = 13, MAX_OUTPUT = 152 };

static int64_t gcd64(int64_t a, int64_t b) {
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a;
}

static void put64(uint8_t *output, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[at + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t yds_speed_scaling(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4u || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_JOBS || length != 1u + 3u * (size_t)input[0]) return -1;
    const size_t jobs = (size_t)input[0];
    int64_t release[MAX_JOBS], deadline[MAX_JOBS], work[MAX_JOBS];
    int active[MAX_JOBS] = {0};
    for (size_t j = 0; j < jobs; ++j) {
        int64_t r = input[1u + 3u*j], d = input[2u + 3u*j], w = input[3u + 3u*j];
        if (r < 0 || r >= d || d > MAX_TIME || w < 1 || w > 8) return -1;
        release[j] = r; deadline[j] = d; work[j] = w; active[j] = 1;
    }
    int64_t staged[MAX_OUTPUT / 8] = {0};
    size_t output_values = 3, stages = 0;
    int64_t energy_num = 0, energy_den = 1;
    size_t remaining = jobs;
    while (remaining > 0) {
        int release_seen[MAX_TIME + 1] = {0}, deadline_seen[MAX_TIME + 1] = {0};
        for (size_t j = 0; j < jobs; ++j) if (active[j]) {
            release_seen[release[j]] = 1; deadline_seen[deadline[j]] = 1;
        }
        int have_best = 0;
        int64_t best_a = 0, best_b = 1, best_work = 0, best_duration = 1;
        for (int64_t a = 0; a <= MAX_TIME; ++a) if (release_seen[a]) {
            for (int64_t b = a + 1; b <= MAX_TIME; ++b) if (deadline_seen[b]) {
                int64_t total = 0;
                for (size_t j = 0; j < jobs; ++j)
                    if (active[j] && release[j] >= a && deadline[j] <= b) total += work[j];
                if (total == 0) continue;
                int64_t duration = b - a;
                if (!have_best || total * best_duration > best_work * duration ||
                    (total * best_duration == best_work * duration &&
                     (a < best_a || (a == best_a && b < best_b)))) {
                    have_best = 1; best_a = a; best_b = b; best_work = total; best_duration = duration;
                }
            }
        }
        if (!have_best) return -1;
        uint64_t job_mask = 0;
        for (size_t j = 0; j < jobs; ++j) if (active[j] && release[j] >= best_a && deadline[j] <= best_b) {
            job_mask |= UINT64_C(1) << j;
        }
        staged[output_values++] = best_a;
        staged[output_values++] = best_b;
        staged[output_values++] = best_work;
        staged[output_values++] = (int64_t)job_mask;

        const int64_t term_num = best_work * best_work * best_work;
        const int64_t term_den = best_duration * best_duration;
        const int64_t common = gcd64(energy_den, term_den);
        energy_num = energy_num * (term_den / common) + term_num * (energy_den / common);
        energy_den *= term_den / common;
        const int64_t energy_gcd = gcd64(energy_num, energy_den);
        energy_num /= energy_gcd; energy_den /= energy_gcd;

        for (size_t j = 0; j < jobs; ++j) if (active[j]) {
            if (release[j] >= best_a && deadline[j] <= best_b) {
                active[j] = 0; --remaining;
            } else {
                int64_t *bounds[2] = {&release[j], &deadline[j]};
                for (size_t k = 0; k < 2; ++k) {
                    int64_t t = *bounds[k];
                    if (t <= best_a) continue;
                    if (t < best_b) *bounds[k] = best_a;
                    else *bounds[k] = t - best_duration;
                }
            }
        }
        ++stages;
    }
    staged[0] = (int64_t)stages; staged[1] = energy_num; staged[2] = energy_den;
    const size_t output_bytes = 8u * output_values;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t bytes[MAX_OUTPUT] = {0};
    for (size_t i = 0; i < output_values; ++i) put64(bytes, 8u*i, staged[i]);
    for (size_t i = 0; i < output_bytes; ++i) output[i] = bytes[i];
    return (int64_t)output_bytes;
}
