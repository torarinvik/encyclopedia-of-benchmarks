#include <cstdint>

extern "C" std::int64_t so1(std::int64_t threshold)
{
    if (threshold < -2'147'483'648LL || threshold > 1'000'000'000LL) return -1;

    std::int64_t first = 1;
    std::int64_t second = 2;
    std::int64_t sum = 0;
    while (second <= threshold) {
        if (second % 2 == 0) sum += second;
        const std::int64_t temporary = first;
        first = second;
        second = temporary + first;
    }
    return sum;
}
