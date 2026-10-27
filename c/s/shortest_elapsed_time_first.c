#include <stddef.h>
#include <stdint.h>

enum { MAX_JOBS = 8, MAX_INPUT = 18, MAX_OUTPUT = 112 };

int64_t shortest_elapsed_time_first(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0];
    if (n64 < 0 || n64 > MAX_JOBS || length != 1 + 2 * (size_t)n64) return -1;
    const size_t n = (size_t)n64;
    int64_t release[MAX_JOBS], remaining[MAX_JOBS], attained[MAX_JOBS] = {0};
    for (size_t job = 0; job < n; ++job) {
        release[job] = input[1 + 2 * job];
        remaining[job] = input[2 + 2 * job];
        if (release[job] < 0 || release[job] > 16 || remaining[job] < 1 || remaining[job] > 12) return -1;
    }
    if (output == NULL) return -2;
    uint8_t trace[MAX_OUTPUT] = {0};
    size_t time = 0, completed = 0;
    while (completed < n && time < MAX_OUTPUT) {
        size_t chosen = n;
        for (size_t job = 0; job < n; ++job)
            if (release[job] <= (int64_t)time && remaining[job] > 0 &&
                (chosen == n || attained[job] < attained[chosen])) chosen = job;
        if (chosen == n) trace[time] = 0;
        else {
            trace[time] = (uint8_t)(chosen + 1);
            ++attained[chosen];
            if (--remaining[chosen] == 0) ++completed;
        }
        ++time;
    }
    if (completed != n) return -1;
    if (capacity < time) return -2;
    for (size_t t = 0; t < time; ++t) output[t] = trace[t];
    return (int64_t)time;
}
