// Multiplicative persistence for nonnegative Java int inputs.
#include <cstdint>

extern "C" std::int64_t number_persistence(std::int64_t input)
{
    if (input < 0 || input > 2147483647) return -1;
    std::int64_t steps = 0;
    while (input >= 10) {
        std::int64_t product = 1;
        std::int64_t remaining = input;
        while (remaining > 0) {
            product *= remaining % 10;
            remaining /= 10;
        }
        input = product;
        ++steps;
    }
    return steps;
}
