#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 32u
#define MAX_INPUT 65u
#define MAX_OUTPUT 64u
#define SQRT2 1.414213562373095048801688724209698079

int64_t cbench_lame_mid_side(const double *input, size_t n, double *output, size_t cap) {
    if (input == NULL || n < 1u || n > MAX_INPUT + 1u) return -1;
    for (size_t i = 0; i < n; ++i) if (!isfinite(input[i])) return -1;
    if (input[0] < 1.0 || input[0] > (double)MAX_SAMPLES || input[0] != trunc(input[0])) return -1;
    size_t count = (size_t)input[0];
    if (n != 1u + 2u * count) return -1;
    for (size_t i = 1; i < n; ++i) if (input[i] < -16.0 || input[i] > 16.0) return -1;
    double staged[MAX_OUTPUT];
    const double factor = SQRT2 * 0.5;
    for (size_t i = 0; i < count; ++i) {
        double left = input[1u + i], right = input[1u + count + i];
        staged[2u*i] = (left + right) * factor;
        staged[2u*i+1u] = (left - right) * factor;
    }
    size_t needed = 2u * count;
    if (output == NULL || cap < needed) return -2;
    for (size_t i = 0; i < needed; ++i) output[i] = staged[i];
    return (int64_t)needed;
}
