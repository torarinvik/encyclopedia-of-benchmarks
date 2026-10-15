/* Bounded integer port of the pinned direct-power polynomial routine. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN

static int64_t integer_power(int64_t base, size_t exponent)
{
    int64_t result = 1;
    for (size_t index = 0; index < exponent; ++index) result *= base;
    return result;
}

int64_t polynomial_evaluation_direct(const int64_t *values, size_t length)
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
    for (size_t index = 0; index < (size_t)count; ++index)
        result += values[index + 2] * integer_power(x, index);
    return result;
}
