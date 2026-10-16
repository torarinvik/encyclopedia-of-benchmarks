#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-1)
#define MAX_N 100
#define MAX_COMPONENT 1000

int64_t in_static_equilibrium(const int64_t *values, size_t length)
{
    if (values == NULL || length < 5) return INVALID_RESULT;
    const int64_t n_value = values[0];
    if (n_value < 1 || n_value > MAX_N || length != 1 + 4 * (size_t)n_value) return INVALID_RESULT;
    const size_t n = (size_t)n_value;
    int64_t total_moment = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t fx = values[1 + i], fy = values[1 + n + i];
        const int64_t lx = values[1 + 2 * n + i], ly = values[1 + 3 * n + i];
        if (fx < -MAX_COMPONENT || fx > MAX_COMPONENT || fy < -MAX_COMPONENT || fy > MAX_COMPONENT ||
            lx < -MAX_COMPONENT || lx > MAX_COMPONENT || ly < -MAX_COMPONENT || ly > MAX_COMPONENT) return INVALID_RESULT;
        total_moment += lx * fy - ly * fx;
    }
    return total_moment == 0 ? 1 : 0;
}
