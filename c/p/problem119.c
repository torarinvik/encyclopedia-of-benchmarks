#include <stdint.h>

static int64_t digit_sum(int64_t value)
{
    int64_t sum = 0;
    while (value > 0) { sum += value % 10; value /= 10; }
    return sum;
}

int64_t problem119(int64_t index)
{
    if (index < 1 || index > 30) return -1;
    int64_t values[10000];
    int count = 0;
    for (int64_t base = 2; base < 100; ++base) {
        int64_t value = base * base;
        for (int exponent = 2; exponent < 100; ++exponent) {
            if (digit_sum(value) == base) values[count++] = value;
            if (value > INT64_MAX / base) break;
            value *= base;
        }
    }
    for (int i = 1; i < count; ++i) {
        const int64_t value = values[i];
        int j = i;
        while (j > 0 && values[j - 1] > value) { values[j] = values[j - 1]; --j; }
        values[j] = value;
    }
    return values[index - 1];
}
