#include <cstdint>

static std::int64_t digit_sum(std::int64_t value) noexcept
{
    std::int64_t sum = 0;
    while (value > 0) { sum += value % 10; value /= 10; }
    return sum;
}

extern "C" std::int64_t problem119(std::int64_t index) noexcept
{
    if (index < 1 || index > 30) return -1;
    std::int64_t values[10000];
    int count = 0;
    for (std::int64_t base = 2; base < 100; ++base) {
        std::int64_t value = base * base;
        for (int exponent = 2; exponent < 100; ++exponent) {
            if (digit_sum(value) == base) values[count++] = value;
            if (value > INT64_MAX / base) break;
            value *= base;
        }
    }
    for (int i = 1; i < count; ++i) {
        const auto value = values[i];
        int j = i;
        while (j > 0 && values[j - 1] > value) { values[j] = values[j - 1]; --j; }
        values[j] = value;
    }
    return values[index - 1];
}
