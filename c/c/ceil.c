#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 256
#define MAX_INPUT_VALUES (1 + 2 * MAX_VALUES)
#define NUMERATOR_LIMIT 1000000000000LL
#define DENOMINATOR_LIMIT 1000000LL
#define RESULT_OFFSET 1000000000001LL

static int64_t ceil_division(int64_t numerator, int64_t denominator)
{
    if (numerator >= 0) return numerator / denominator + (numerator % denominator != 0);
    return -((-numerator) / denominator);
}

int64_t ceil_benchmark(const int64_t *values, size_t length)
{
    if (length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_VALUES) return -1;
    const size_t count = (size_t)count_value;
    if (length != 1 + 2 * count) return -1;
    for (size_t i = 0; i < count; ++i) {
        const int64_t numerator = values[1 + 2 * i];
        const int64_t denominator = values[2 + 2 * i];
        if (numerator < -NUMERATOR_LIMIT || numerator > NUMERATOR_LIMIT ||
            denominator < 1 || denominator > DENOMINATOR_LIMIT) return -1;
    }
    int64_t checksum = 0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t result = ceil_division(values[1 + 2 * i], values[2 + 2 * i]);
        checksum += (int64_t)(i + 1) * (result + RESULT_OFFSET);
    }
    return checksum;
}
