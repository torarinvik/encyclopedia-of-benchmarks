/* Multiply two bounded signed operands; the bounds guarantee an i64 result. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN

int64_t multiply_digit(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t first = values[0];
    const int64_t second = values[1];
    if (first < -INT64_C(1000000000) || first > INT64_C(1000000000) ||
        second < -INT64_C(1000000000) || second > INT64_C(1000000000)) return INVALID_RESULT;
    return first * second;
}
