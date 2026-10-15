#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 4096
#define MAX_ABS_VALUE INT64_C(1000000000)
#define INVALID_RESULT (-1.0e300)

double average(const int64_t *values, size_t length)
{
    if (length == 0 || length > MAX_INPUT_LENGTH || values == NULL) return INVALID_RESULT;
    int64_t sum = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = values[index];
        if (value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE) return INVALID_RESULT;
        sum += value;
    }
    return (double)sum / (double)length;
}
