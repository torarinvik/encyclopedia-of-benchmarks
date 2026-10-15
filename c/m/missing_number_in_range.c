/* XOR a consecutive signed 32-bit range using portable zero-extended bit patterns. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024
#define INVALID_RESULT (-2147483649LL)

static uint64_t encode_i32(int64_t value)
{
    return (uint64_t)(value < 0 ? value + INT64_C(4294967296) : value);
}

int64_t missing_number_in_range(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_VALUES) return INVALID_RESULT;
    int64_t low = values[0];
    int64_t high = values[0];
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < INT32_MIN || values[i] > INT32_MAX) return INVALID_RESULT;
        if (values[i] < low) low = values[i];
        if (values[i] > high) high = values[i];
    }
    if (high - low != (int64_t)length) return INVALID_RESULT;
    bool seen[MAX_VALUES + 1] = {false};
    uint64_t actual = 0;
    for (size_t i = 0; i < length; ++i) {
        size_t slot = (size_t)(values[i] - low);
        if (seen[slot]) return INVALID_RESULT;
        seen[slot] = true;
        actual ^= encode_i32(values[i]);
    }
    uint64_t expected = 0;
    for (int64_t value = low; value <= high; ++value)
        expected ^= encode_i32(value);
    uint64_t result = expected ^ actual;
    return result <= INT32_MAX ? (int64_t)result : (int64_t)result - INT64_C(4294967296);
}
