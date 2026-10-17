#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_GENES = 64 };

int64_t mutate(const double *input, size_t length, double *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > 2 + 2 * MAX_GENES) return -1;
    const double mu = input[0], count_value = input[1];
    if (!isfinite(mu) || mu < 0.0 || mu > 1.0 || !isfinite(count_value) ||
        floor(count_value) != count_value || count_value < 0.0 || count_value > MAX_GENES) return -1;
    const size_t count = (size_t)count_value;
    if (length != 2 + 2 * count) return -1;
    for (size_t index = 0; index < count; ++index) {
        const double gene = input[2 + index];
        if (gene != 0.0 && gene != 1.0) return -1;
    }
    for (size_t index = 0; index < count; ++index) {
        const double draw = input[2 + count + index];
        if (!isfinite(draw) || draw < 0.0 || draw >= 1.0) return -1;
    }
    if (output == NULL || capacity < count) return -2;
    for (size_t index = 0; index < count; ++index) {
        const double gene = input[2 + index];
        const double draw = input[2 + count + index];
        output[index] = draw < mu ? 1.0 - gene : gene;
    }
    return (int64_t)count;
}
