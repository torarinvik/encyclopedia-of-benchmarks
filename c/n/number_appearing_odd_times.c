/* XOR-fold an int32 array to find its unique odd-frequency value. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096
#define INVALID_RESULT (-INT64_C(2147483649))
#define INT32_MIN_VALUE INT64_C(-2147483648)
#define INT32_MAX_VALUE INT64_C(2147483647)

int64_t number_appearing_odd_times(const int64_t *values, size_t length)
{
    if (length == 0 || length > MAX_LENGTH || values == NULL) return INVALID_RESULT;
    int32_t result = 0;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN_VALUE || values[index] > INT32_MAX_VALUE)
            return INVALID_RESULT;
        result ^= (int32_t)values[index];
    }
    return result;
}
