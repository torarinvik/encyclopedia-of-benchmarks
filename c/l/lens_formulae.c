/* Three reciprocal thin-lens formula solves. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double lens_formulae(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t operation = values[0];
    const int64_t first = values[1];
    const int64_t second = values[2];
    if (operation < 0 || operation > 2 || first == 0 || second == 0 ||
        first < -1000000 || first > 1000000 || second < -1000000 || second > 1000000)
        return INVALID_RESULT;
    if (operation == 0) {
        if (first == second) return INVALID_RESULT;
        return 1.0 / ((1.0 / (double)second) - (1.0 / (double)first));
    }
    if (operation == 1) {
        if (first == second) return INVALID_RESULT;
        return 1.0 / ((1.0 / (double)second) - (1.0 / (double)first));
    }
    if (first == -second) return INVALID_RESULT;
    return 1.0 / ((1.0 / (double)second) + (1.0 / (double)first));
}
