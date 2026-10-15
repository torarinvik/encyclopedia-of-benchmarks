/* Bounded integer port of the pinned floating-point Horner routine. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN

int64_t polynomial_evaluation(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 10) return INVALID_RESULT;
    const int64_t count = values[0];
    const int64_t x = values[1];
    if (count < 0 || count > 8 || length != (size_t)(count + 2)) return INVALID_RESULT;
    if (x < -10 || x > 10) return INVALID_RESULT;
    for (size_t index = 0; index < (size_t)count; ++index) {
        if (values[index + 2] < -1000 || values[index + 2] > 1000) return INVALID_RESULT;
    }
    int64_t result = 0;
    for (size_t index = (size_t)count; index > 0; --index) {
        result = result * x + values[index + 1];
    }
    return result;
}
